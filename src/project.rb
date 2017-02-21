require 'configatron'
require 'yaml'
require_relative 'error'
require_relative 'config'

module GitlabHook
  module Project
    @project
    @project_config_file
    @project_code

    attr_reader :project, :project_code

    module_function

    def init(project_path)
      # define path and code
      @project             = project_path.chomp('/').reverse.chomp('/').reverse
      @project_code        = @project.sub(/[^A-z0-9]+/, '_').downcase
      @project_config_file = configatron.app.path.base.projects + '/' + @project + '/config.yml'

      # read config
      configatron.projects[@project_code]          = GitlabHook::Config::read @project_config_file
      configatron.projects[@project_code + '_raw'] = GitlabHook::Config::read_raw @project_config_file
    end

    def has_config?
      configatron.projects[@project_code]
    end

    def config
      if @project_code.nil? or configatron.projects[@project_code].nil?
        raise GitlabHook::Error, 'Project is not defined.'
      end
      configatron.projects[@project_code]
    end

    def config_raw
      if @project_code.nil? or configatron.projects[@project_code].nil?
        raise GitlabHook::Error, 'Project is not defined.'
      end
      configatron.projects[@project_code + '_raw']
    end

    def config_raw=(content)
      until Dir.exist? File.dirname(@project_config_file)
        Dir.mkdir File.dirname(@project_config_file)
      end
      fw = File.open(@project_config_file, 'w')
      fw.write content.gsub(/^#[^\n\r]*/m, '')
                 .gsub(/^[\n]+/m, '')
      fw.close
    end

    def config_sample_raw
      GitlabHook::Config::read_raw configatron.app.path.base.projects + '/config.yml.sample'
    end

    def team_by_label(label)
      return nil if config['labels']
      config['labels'][label]
    end

    def find_receiver(team, type)
      return nil if config['receivers']
      return nil if config['receivers'][type]
      config['receivers'][type][team]
    end
  end
end
