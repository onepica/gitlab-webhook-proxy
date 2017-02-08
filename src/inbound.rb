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

      receiver = GitlabHook::MergeRequest.match_receiver data

      pp receiver
      exit 34

      if receiver
        GitlabHook::Sender.new.send(data, {receiver: receiver})
        return true
      end

      false
    end
  end
end
