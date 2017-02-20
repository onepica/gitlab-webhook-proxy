require 'gitlab'
require 'configatron'

module GitlabHook
  module GitlabClient
    module Auth
      module_function
      def gitlab_user_token(username:, password:)
        Gitlab.client(endpoint: configatron.app.gitlab.endpoint)
          .session(username, password).private_token
      end
    end
  end
end
