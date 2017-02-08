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
    def self.run_server
      server = WEBrick::HTTPServer.new(:Port => configatron.app.web.port)
      server.mount_proc '/inbound' do |request, response|
        data = read_data(request)

        begin
          GitlabHook::Project::init(
            URI(data['repository']['homepage']).path
          )
          GitlabHook::Inbound.new.forward data
        rescue GitlabHook::Error => e
          pp e.message
          pp e.backtrace
          pp '-----------'
          exit 56
          response.status = 404
          return "error: #{e.message}"
        rescue => e
          pp e.message
          pp e.backtrace
          pp '+++++++____+++++++'
          exit 56
          # response.status = 503
          return "error [#{e.class}]: #{e.message}\n#{e.backtrace}"
        else
        end
      end

      trap 'INT' do
        server.shutdown
      end
      server.start
    end

    def self.read_data(request)
      if request.body.empty?
        raise 'Invalid request.'
      end
      JSON.parse request.body
    end
  end
end
