require 'webrick'
require 'pp'
require 'json'
require 'uri'
require 'gitlab'
require 'configatron'

require_relative 'error'
require_relative 'project'
require_relative 'inbound'

require_relative '../config/app_default'
if File.exist? __dir__ + '/../config/app.rb'
  require_relative '../config/app'
else
  require_relative '../config/app.dist'
end

module GitlabHook
  module Server
    @request
    @response
    @request_data
    def self.run_server
      server = WEBrick::HTTPServer.new(:Port => configatron.app.web.port)
      server.mount_proc '/inbound' do |request, response|
        @request      = request
        @response     = response
        puts process_gitlab_webhook
      end

      trap 'INT' do
        server.shutdown
      end
      server.start
    end

    def self.process_gitlab_webhook
      begin
        output = ''
        @response.set_error 'aaa'
        @request_data = read_data

        GitlabHook::Project::init(
          URI(@request_data['repository']['homepage']).path
        )
        GitlabHook::Inbound.new.forward @request_data
      rescue GitlabHook::Error => e
        @response.status = 404
        output = "error [#{e.class}]: #{e.message}\n#{e.backtrace}"
      rescue => e
        @response.status = 503
        output = "error [#{e.class}]: #{e.message}\n#{e.backtrace}"
      end
      output
    end

    def self.read_data
      if @request.body.nil? or @request.body.empty?
        raise 'Invalid request.'
      end
      JSON.parse @request.body
    end
  end
end
