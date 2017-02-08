require 'gitlab'

require_relative 'gitlab_client/client'

module GitlabHook
  module MergeRequest
    extend GitlabHook::GitlabClient::Client

    module_function

    # @return [Array]
    def fetch_labels(project_id, merge_id)
      gitlab_super
        .merge_request(project_id, merge_id).labels
    end

    def match_receiver(data)
      fetch_labels(
        data['object_attributes']['target_project_id'], data['object_attributes']['id']
      ).each do |label|
        team = GitlabHook::Project.team_by_label label
        return GitlabHook::Project.find_receiver team, 'slack' if team
      end

      if data['object_attributes']['assignee_id']
        team = GitlabHook::User.new(data['object_attributes']['assignee_id']).config['team']
        return GitlabHook::Project.find_receiver team, 'slack' if team
      end
    end
  end
end
