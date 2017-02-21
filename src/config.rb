require_relative 'error'

module GitlabHook
  module Config
    module_function

    def read(path)
      raise GitlabHook::Error, ('LFI protection! There is not way to use parent directory. ' + path) if path.index('..')
      return nil unless File.exist? configatron.app.path.root + '/' + path

      YAML.load_file(configatron.app.path.root + '/' + path.gsub(/^[\/]+/, ''))
    end

    def read_raw(path)
      raise GitlabHook::Error, ('LFI protection! There is not way to use parent directory. ' + path) if path.index('..')
      return nil unless File.exist? configatron.app.path.root + '/' + path

      File.read(configatron.app.path.root + '/' + path.gsub(/^[\/]+/, ''))
    end
  end
end
