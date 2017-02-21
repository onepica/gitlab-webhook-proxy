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
end

layout_params = {}

# @var [Sinatra::Request] request
# @var [Sinatra::Response] response
require 'pp'
pp 'aaa'
before '/app/*' do
  until logged
    session[:previous_url] = request.path
    @error                 = 'Sorry, you need to be logged into GitLab to visit this page.'
    halt erb(:login_form)
  end
end

get '/' do
  erb :index
end

get '/login/form' do
  erb :login_form
end

post '/login/attempt' do
  session[:identity] = params['username']

  session[:auth] = {}
  begin
    require_relative 'src/gitlab_client/auth'
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

get '/logout' do
  session.delete(:identity)
  session.delete(:auth)
  erb "<div class='alert alert-message'>Logged out</div>"
end

get '/app/project' do
  require_relative 'src/gitlab_client/client'
  # Gitlab::PaginatedResponse
  @projects = GitlabHook::GitlabClient::Client::gitlab(session[:auth][:token]).projects
  erb :projects
end

get '/app/project/config/:id' do
  require_relative 'src/gitlab_client/client'
  # Gitlab::PaginatedResponse
  @project = GitlabHook::GitlabClient::Client::gitlab(session[:auth][:token]).project params['id']
  @project_path = @project.web_url

  begin
    require_relative 'src/project'
    GitlabHook::Project::init(
      URI(@project.web_url).path
    )
    @content = GitlabHook::Project::config_raw
  rescue GitlabHook::Error => e
    @content = GitlabHook::Project::config_sample_raw
                 .gsub(/^#-[^\n\r]*/m, '')
                 .gsub(/[\n]{2,}/m, '')
  end

  erb :project
end
