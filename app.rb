require 'rubygems'
require 'sinatra'

# region Load configuration
require 'configatron'
require_relative 'config/app_default'
if File.exist? __dir__ + '/config/app.rb'
  require_relative 'config/app'
else
  require_relative 'config/app.dist'
end
# endregion

require_relative 'src/project'
require_relative 'src/user'
require_relative 'src/gitlab_client/auth'
require_relative 'src/gitlab_client/client'
require_relative 'src/log_point'
require_relative 'src/vcs_adapter/gitlab_vcs'

set :bind, configatron.app.web.ip
set :port, configatron.app.web.port
set :cookie_options, domain: configatron.app.web.host

configure do
  enable :sessions
end

helpers do
  def username
    session[:identity] ? session[:identity] : 'Hello stranger'
  end

  def logged
    session[:identity] and session[:auth] and session[:auth][:token]
  end

  def jira_logged
    session[:jira_identity] and session[:jira_auth] and session[:jira_auth][:token]
  end

  def project_has_config(project)
    GitlabHook::Project::init(
        URI(project.web_url).path
    )
    GitlabHook::Project::has_config?
  end

  def project_webhook_url
    (configatron.app.web.port == '443' ? 'https' : 'http') + '://' +
        configatron.app.web.host +
        (configatron.app.web.port != '80' ? ':' + configatron.app.web.port : '') +
        '/inbound/' + configatron.app.web.inbound_token
  end

  def project_template
    GitlabHook::Project::config_sample_raw
  end

  def user_template
    GitlabHook::User.new(nil).config_sample_raw
  end
end

# @var [Sinatra::Request] request
# @var [Sinatra::Response] response
before '/app/*' do
  until logged
    session[:previous_url] = request.path
    @error                 = 'Sorry, you need to be logged into GitLab to visit this page.'
    halt erb(:login_form)
  end
end

before '/jira-app/*' do
  until jira_logged
    session[:previous_url] = request.path
    @error                 = 'Sorry, you need to be logged into JIRA to visit this page.'
    halt erb(:login_form)
  end
end

# --------------------
get '/' do
  erb :index
end

# --------------------
get '/login/form' do
  erb :login_form
end

# --------------------
post '/login/attempt' do
  session[:identity] = params['username']

  session[:auth] = {}
  begin
    session[:auth][:token] = GitlabHook::GitlabClient::Auth::gitlab_user_token(
      username: params['username'], password: params['password']
    )
  rescue Gitlab::Error::Unauthorized => e
    @error = 'Sorry, we could not authorize you.'
    halt erb(:login_form)
  end

  # redirect logged user back
  redirect to (session[:previous_url] || '/')
end

# --------------------
get '/logout' do
  session.delete(:identity)
  session.delete(:auth)
  erb "<div class='alert alert-message'>Logged out</div>"
end

# --------------------
get '/app/project' do
  # Gitlab::PaginatedResponse
  @projects = GitlabHook::Vcs::adapter('gitlab').client(session[:auth][:token]).projects
  erb :projects
end

# --------------------
get '/app/project/config/:id' do
  until params['id']
    redirect to (session[:previous_url] || '/')
  end
  # Gitlab::PaginatedResponse
  @project = GitlabHook::Vcs::adapter('gitlab').client(session[:auth][:token]).project params['id']
  @project_path = @project.web_url

  GitlabHook::Project::init(
    URI(@project.web_url).path
  )
  if GitlabHook::Project::has_config?
    @content = GitlabHook::Project::config_raw
  else
    @content = GitlabHook::Project::config_sample_raw
                 .gsub(/^#-[^\n\r]*/m, '')
                 .gsub(/[\n]{2,}/m, '')
  end

  session[:previous_url] = request.path

  erb :project
end

# --------------------
post '/app/project/save/config' do
  until params['id']
    redirect to (session[:previous_url] || '/')
  end

  @project = GitlabHook::Vcs::adapter('gitlab').client(session[:auth][:token]).project params['id']

  GitlabHook::Project::init(
    URI(@project.web_url).path
  )
  GitlabHook::Project::config_raw = params['config']

  # log identity who updated a project
  GitlabHook::LogPoint::write 'Project config has been updated by ' + session[:identity],
                  'project_' + GitlabHook::Project::project_code,
                  Logger::INFO

  # redirect the user back
  redirect to (session[:previous_url] || '/')
end

# --------------------
get '/app/user' do
  @user = GitlabHook::Vcs::adapter('gitlab').client(session[:auth][:token]).user
  @user_config = GitlabHook::User.new(@user.id, data: @user)
  if @user_config.config
    @content = @user_config.config_raw
  else
    @content = '# No content here yet. Press edit to add new configuration.' + @user_config.config.to_s
  end
  erb :user
end

# --------------------
get '/app/user/edit' do
  # Gitlab::PaginatedResponse
  @user = GitlabHook::Vcs::adapter('gitlab').client(session[:auth][:token]).user
  user_config = GitlabHook::User.new(@user.id, data: @user)
  if user_config.config
    @content = user_config.config_raw
  else
    @content = user_config.config_sample_raw
  end
  erb :user_edit
end

# --------------------
post '/app/user/save/config' do
  @user = GitlabHook::Vcs::adapter('gitlab').client(session[:auth][:token]).user

  user_config = GitlabHook::User.new(@user.id, data: @user)
  user_config.config_raw = params['config']

  # redirect the user back
  redirect to '/app/user'
end

# --------------------
post '/inbound/:token' do
  require_relative 'src/inbound'

  # debug
  puts "token: #{params['token']}"

  if params['token'] != configatron.app.web.inbound_token
    return 'error: Invalid token.'
  end

  request.body.rewind
  request_data = JSON.parse request.body.read

  if !request_data or request_data.nil?
    # debug
    puts 'data: false'
    return 'error: Invalid request.'
  end

  # debug
  puts 'data: true'

  GitlabHook::Project::init(
      URI(request_data['repository']['homepage']).path
  )

  begin
    GitlabHook::Inbound.new.forward request_data
  rescue GitlabHook::Error => e
    response.status = 404
    # debug
    puts "error [#{e.class}]: #{e.message}\n#{e.backtrace.join("\n")}"
    return "error [#{e.class}]: #{e.message}"
  rescue => e
    response.status = 503
    # debug
    puts "error [#{e.class}]: #{e.message}\n#{e.backtrace.join("\n")}"
    return "error [#{e.class}]"
  end
end
