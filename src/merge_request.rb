require 'gitlab'

require_relative 'vcs_adapter/gitlab_vcs'
require_relative 'project'

module GitlabHook
  class MergeRequest
    @request_data
    @user_author
    @user_assignee
    @action_allowed

    def initialize(request_data)
      @request_data = request_data

      @action_allowed = Project::action_allowed? @request_data['object_kind'],
                                                 @request_data['object_attributes']['action']

      unless @action_allowed
        LogPoint::write sprintf(
                            'action not allowed: %s, %s.',
                            @request_data['object_kind'],
                            @request_data['object_attributes']['action']
                        ), 'inbound', Logger::WARN
      end
    end

    ##
    # Fetch labels
    #
    # @return [Array]
    #
    def fetch_labels
      GitlabHook::VcsAdapter::vcs('gitlab').super_user.merge_request(
          @request_data['object_attributes']['target_project_id'], @request_data['object_attributes']['id']
      ).labels
    end

    def match_receivers
      receivers = {
          team: [],
          assignee: nil,
          merged: nil,
      }

      # "merge" action should be managed by a user at least
      if @request_data['object_kind'] == 'merge' and
          user_author.subscribed_for?('notify_merge', 'merge_request')
        receivers[:merged] = '@' + user_author.service_username('slack')
      end

      unless @action_allowed
        receivers
      end

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
      user_assignee.subscribed_for?('duplicate_assigned_requests_to_team', 'merge_request')
    end

    def can_send_to_assignee?
      ((!user_assignee.subscribed_for?('assignment', 'merge_request').nil? and
          true == user_assignee.subscribed_for?('assignment', 'merge_request')) or
          (user_assignee.subscribed_for?('assignment', 'merge_request').nil? and
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
