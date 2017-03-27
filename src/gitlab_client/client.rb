require 'gitlab'
require 'configatron'

module GitlabHook
  module GitlabClient
    module Client
      module_function
      # @return Gitlab::Client
      def gitlab(token)
        Gitlab.client(
          endpoint: configatron.app.gitlab.endpoint,
          private_token: token
        )
      end

      def gitlab_super
        gitlab(configatron.app.gitlab.super.private_token)
      end

      def user_name(id)
        user(id).username
      end

      def user(id)
        gitlab_super.user(id)
      end
    end
  end
end
