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

    attr_accessor :project
    attr_accessor :project_code

    module_function

    def init(project_path)
      # define path and code
      @project = project_path.chomp('/').reverse.chomp('/').reverse
      @project_code = @project.gsub(/[^A-z0-9]+/, '_').downcase
      @project_config_file = configatron.app.path.base.projects + '/' + @project + '/config.yml'

      # read config
      configatron.projects[@project_code] = GitlabHook::Config::read @project_config_file
      configatron.projects[@project_code + '_raw'] = GitlabHook::Config::read_raw @project_config_file
    end

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
      until Dir.exist? File.dirname(@project_config_file)
        FileUtils.mkdir_p File.dirname(@project_config_file)
      end

      File.open(@project_config_file, 'w')
          .write(content)
          .close
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
      return nil until config['labels']
      config['labels'][label]
    end

    def find_receiver(team, type)
      return nil until config['receivers']
      return nil until config['receivers'][type]
      config['receivers'][type][team]
    end
  end
end
