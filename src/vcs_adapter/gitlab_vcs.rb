require 'configatron'
require_relative '../gitlab_client/client'

module GitlabHook
  module VcsAdapter
    class GitlabVcs
      @low_client

      def initialize
        @low_client = GitlabHook::GitlabClient::Client
      end

      def super_user
        @low_client::gitlab_super
      end

      def client(token)
        @low_client::gitlab(token)
      end

      def username_by_id(id)
        @low_client::user_name(id)
      end

      def user(id)
        @low_client::user(id)
      end
    end
  end
end
