require 'configatron'
require 'yaml'
require 'rake/file_utils'
require_relative 'error'
require_relative 'config'

module GitlabHook
  module Project
    @project
    @project_config_file
    @project_code

    module_function

    attr_reader :project
    attr_reader :project_code

    def init(project_path)
      # define path and code
      @project = project_path.chomp('/').reverse.chomp('/').reverse
      @project_code = @project.gsub(/[^A-z0-9]+/, '_').downcase
      @project_config_file = configatron.app.path.base.projects + '/' + @project + '/config.yml'

      # read config
      configatron.projects[@project_code] = GitlabHook::Config::read @project_config_file
      configatron.projects[@project_code + '_raw'] = GitlabHook::Config::read_raw @project_config_file
    end

    ##
    # Attribute reader for @project_code
    #
    # @return [String]
    #
    def project_code
      @project_code
    end

    ##
    # Check if config exists for loaded project
    #
    # @return [TrueClass|FalseClass]
    #
    def has_config?
      configatron.projects[@project_code]
    end

    ##
    # Get config
    #
    # @return [Hash]
    #
    def config(key = nil)
      if @project_code.nil? or configatron.projects[@project_code].nil?
        raise GitlabHook::Error, 'Project is not defined.'
      end

      config = configatron.projects[@project_code]
      return nil unless config

      key ? config[key] : config
    end

    ##
    # Get config content from file
    #
    # @return [String]
    #
    def config_raw
      if @project_code.nil? or configatron.projects[@project_code].nil?
        raise GitlabHook::Error, 'Project is not defined.'
      end
      configatron.projects[@project_code + '_raw']
    end

    ##
    # Write config to file
    #
    # @param [String] content
    #
    def config_raw=(content)
      unless content
        raise GitlabHook::Error, 'Empty content.'
      end

      # create dirs in case they don't exist
      unless Dir.exist? File.dirname(@project_config_file)
        FileUtils.mkdir_p File.dirname(@project_config_file)
      end

      fw = File.open(@project_config_file, 'w')
      fw.write(content)
      fw.close
    end

    ##
    # Get sample content of config file
    #
    # @return [String]
    #
    def config_sample_raw
      GitlabHook::Config::read_raw configatron.app.path.base.projects + '/config.yml.sample'
    end

    def team_by_label(label)
      return nil unless config['labels']
      config['labels'][label]
    end

    ##
    # Teams configuration
    #
    # @return [String]
    #
    def teams_config
      config('teams')
    end

    ##
    # Teams configuration
    #
    # @return [String]
    #
    def team_by_user(username)
      return nil unless teams_config
      teams_config.each do |team, users|
        return team if users.include? username
      end
    end

    def find_receiver(team, type)
      return nil unless config['receivers'] and config['receivers'][type]
      config['receivers'][type][team]
    end

    ##
    # Check if inbound action is allowed
    #
    # @param [String] type This is a webhook type, like merge_request, push, etc.
    # @param [String] action This is an action type of a webhook. E.g. for merge_request it can be merge, open, etc.
    #
    def action_allowed?(type, action)
      # allow type/action "merge_request"/"open" by default
      return true if type == 'merge_request' and action == 'open'

      return false unless config['triggers'] and config['triggers'][type] and
          config['triggers'][type]['action'] and
          config['triggers'][type]['action'].kind_of?(Array) and
          !config['triggers'][type]['action'].empty?

      config['triggers'][type]['action'].include? action
    end
  end
end
