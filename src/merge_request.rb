require 'gitlab'

require_relative 'gitlab_client/client'

module GitlabHook
  class MergeRequest
    include GitlabHook::GitlabClient::Client

    @request_data
    @user_author
    @user_assignee

    def initialize(request_data)
      @request_data = request_data
    end

    # module_function

    # @return [Array]
    def fetch_labels(project_id, merge_id)
      gitlab_super
        .merge_request(project_id, merge_id).labels
    end

    def match_receivers
      receivers = {
          team: [],
          assignee: [],
      }

      fetch_labels(
          @request_data['object_attributes']['target_project_id'], @request_data['object_attributes']['id']
      ).each do |label|
        team = project.team_by_label label
        if team
          receivers[:team] << project.find_receiver(team, 'slack')
        end
      end

      # it couldn't determine a receiver
      # Try find it by author
      if receivers.empty? and user_author.team
        # pick up an author's team from project config or from user config
        team = (project.find_user_team(user_author.username) || project.find_receiver(user_author.team, 'slack'))
        receivers[:team] << team if team
      end

      # Send personal message to assignee
      # User or Project should have config "ignore_assignee: true" to ignore it
      # User flag has higher priority
      if ((!user_assignee.config('ignore_assignee').nil? and
          false == user_assignee.config('ignore_assignee')) or
          (user_assignee.config('ignore_assignee').nil? and
              true != project.config('ignore_assignee'))
      ) and user_assignee.service_username('slack')
        receivers[:assignee] = '@' + user_assignee.service_username('slack')
      end

      receivers
    end

    def user_author
      until @user_author
        @user_author = user(@request_data['object_attributes']['author_id'])
      end
      @user_author
    end

    def user_assignee
      until @user_assignee
        @user_assignee = user(@request_data['object_attributes']['assignee_id'])
      end
      @user_assignee
    end

    protected

    def user(id)
      GitlabHook::User.new(id)
    end

    def project
      GitlabHook::Project
    end
  end
end
