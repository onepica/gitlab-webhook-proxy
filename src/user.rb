require 'configatron'
require_relative 'vcs_adapter/gitlab_vcs'
require_relative 'config'

module GitlabHook
  class User
    include GitlabHook::Config

    @data
    attr_reader :data

    def initialize(id, data: nil)
      @data = data
      @data = load_user(id) if id && data.nil?

      configatron.users[@data.username] = read(config_file) if @data
    end

    def config(key = nil)
      return nil unless @data and @data.username
      return nil unless configatron.users[@data.username]

      key ? configatron.users[@data.username][key] : configatron.users[@data.username]
    end

    def subscribed_for?(event, type)
      return nil unless config('subscribe').kind_of? Hash and
        config('subscribe')[type].kind_of? Hash

      config('subscribe')[type][event]
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
      fw = File.open(config_file, 'w')
      fw.write(content)
      fw.close
    end

    def config_sample_raw
      read_raw(configatron.app.path.base.users + '/username.yml.sample')
    end

    def team
      config ? config['team'] : nil
    end

    def ignore_assignee
      config('ignore_assignee')
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

    def name
      return nil unless @data
      @data.name
    end

    protected

    def load_user(id)
      GitlabHook::VcsAdapter::vcs('gitlab').user(id)
    end
  end
end
