require 'configatron'
require_relative 'config'

module GitlabHook
  module Vcs
    @adapters = []

    def adapter(type)
      if 'gitlab' == type
        return @adapters[type] if @adapters[type]

        require_relative 'gitlab_client/client'
        @adapters[type] = new GitlabHook::VcsAdapter::GitlabVcs
      else
        raise "Type #{type} wasn't implemented yet."
      end
    end
  end
end
