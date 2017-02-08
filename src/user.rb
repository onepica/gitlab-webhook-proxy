require 'configatron'
require_relative 'gitlab_client/client'
require_relative 'config'

module GitlabHook
  class User
    include GitlabHook::GitlabClient::Client
    include GitlabHook::Config

    @data
    attr_reader :data

    module_function

    def initialize(id)
      @data = gitlab_super.user id

      if @data
        configatron.users[@data.username] = read(configatron.app.path.base.users + '/' + @data.username)
      end
    end

    def config
      configatron.users[@data.username]
    end

    def team
      config['team']
    end

    def service_username(service)
      return nil unless config[service]
      config[service]['username']
    end
  end
end
