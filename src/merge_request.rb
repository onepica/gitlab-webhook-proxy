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

    ##
    # Fetch labels
    #
    # @return [Array]

    def fetch_labels
      gitlab_super
          .merge_request(
              @request_data['object_attributes']['target_project_id'], @request_data['object_attributes']['id']
          ).labels
    end

    def match_receivers
      receivers = {
          team: [],
          assignee: [],
      }

      # Determine receiver by a label
      fetch_labels.each do |label|
        team = project.team_by_label label
        if team
          receivers[:team] << project.find_receiver(team, 'slack')
        end
      end

      # if it couldn't determine a receiver try to find it by author
      if receivers[:team].empty? and user_author.team
        receivers[:team] << receiver_by_author
      end

      # Send personal message to assignee
      # User or Project should have config "ignore_assignee: true" to ignore it
      # User flag has higher priority
      if can_send_to_assignee?
        receivers[:assignee] = '@' + user_assignee.service_username('slack')

        # drop team receivers if user won't notify them
        receivers[:team] = [] unless duplicate_message_to_team?
      end

      receivers
    end

    ##
    # Get an author's team receiver by project config or by user config
    #
    # @return [String]
    #
    def receiver_by_author
      receiver = project.find_receiver(
          project.team_by_user(user_author.username), 'slack'
      )
      project.find_receiver(user_author.team, 'slack') unless receiver

      receiver
    end

    ##
    # Author User
    #
    # @return [User]
    #
    def user_author
      unless @user_author
        @user_author = user(@request_data['object_attributes']['author_id'])
      end
      @user_author
    end

    ##
    # Assignee User
    #
    # @return [User]
    #
    def user_assignee
      unless @user_assignee
        @user_assignee = user(@request_data['object_attributes']['assignee_id'])
      end
      @user_assignee
    end

    protected

    def duplicate_message_to_team?
      user_assignee.config('duplicate_assigned_requests_to_team')
    end

    def can_send_to_assignee?
      ((!user_assignee.config('ignore_assignee').nil? and
          false == user_assignee.config('ignore_assignee')) or
          (user_assignee.config('ignore_assignee').nil? and
              true != project.config('ignore_assignee'))
      ) and user_assignee.service_username('slack')
    end

    def user(id)
      GitlabHook::User.new(id)
    end

    def project
      GitlabHook::Project
    end
  end
end
