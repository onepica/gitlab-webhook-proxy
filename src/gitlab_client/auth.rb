require 'gitlab'

module GitlabHook
  module GitlabClient
    module Auth
      # 'a.roslik@astoundcommerce.com', '&ITpn7itNI&N'
      def gitlab_user_token(username, password)
        Gitlab.client(endpoint: configatron.app.gitlab.endpoint)
          .session(username, password).private_token
      end
    end
  end
end
