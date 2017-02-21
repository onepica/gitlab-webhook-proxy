require 'configatron'
require_relative 'gitlab_client/client'
require_relative 'config'

module GitlabHook
  class User
    include GitlabHook::GitlabClient::Client
    include GitlabHook::Config

    @data
    attr_reader :data

    def initialize(id, data: nil)
      @data = data
      @data = load_user(id) if id && data.nil?

      configatron.users[@data.username] = read(config_file) if @data
    end

    def config(key = nil)
      config = configatron.users[@data.username]
      return nil unless config

      key ? config[key] : config
    end

    def config_raw
      read_raw config_file
    end

    def config_file
      configatron.app.path.base.users + '/' + @data.username + '.yml' if @data and @data.username
    end

    def config_raw=(content)
      unless content
        raise GitlabHook::Error, 'Empty content.'
      end
      content = content.gsub(/^#[^\n\r]*/m, '')
        .gsub(/^[\n]+/m, '')
      fw = File.open(config_file, 'w')
      fw.write content.gsub(/^#[^\n\r]*/m, '')
                 .gsub(/^[\n]+/m, '')
      fw.close
    end

    def config_sample_raw
      read_raw(configatron.app.path.base.users + '/username.yml.sample')
    end

    def team
      config ? config['team'] : nil
    end

    def service_username(service = 'slack')
      return nil unless config
      return nil unless config[service]
      config[service]['username']
    end

    def username
      return nil unless @data
      @data.username
    end

    protected

    def load_user(id)
      gitlab_super.user(id)
    end
  end
end
