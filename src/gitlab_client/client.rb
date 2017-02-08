require 'gitlab'
require 'configatron'

module GitlabHook
  module GitlabClient
    module Client
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
        gitlab(configatron.app.gitlab.super.private_token)
          .user(id).username
      end
    end
  end
end
