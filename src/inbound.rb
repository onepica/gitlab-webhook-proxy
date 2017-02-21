require 'configatron'
require 'yaml'

require_relative 'merge_request'

require_relative 'sender'

require_relative 'error'

module GitlabHook
  class Inbound
    def forward(data)
      if data['object_kind'] != 'merge_request'
        raise GitlabHook::Error, 'Only merge_request allowed.'
      end

      receivers = GitlabHook::MergeRequest.new(data).match_receivers

      if receivers[:team] or receivers[:assignee]
        receivers[:team].each do |receiver|
          GitlabHook::Sender.new.send(data, {channel: receiver})
        end

        GitlabHook::Sender.new.send(data, {receiver: receivers[:assignee]}) if receivers[:assignee]

        return true
      end

      false
    end
  end
end
