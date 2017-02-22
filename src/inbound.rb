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

      puts receivers

      result = true

      if receivers[:team] or receivers[:assignee]
        receivers[:team].each do |receiver|
          response = GitlabHook::Sender.new.send(data, {
              channel: receiver,
              template_name: 'group',
          })
          result = (response and response.instance_of? Net::HTTPOK) ? result : false

          # debug
          puts receiver
          puts response.class
        end

        if receivers[:assignee]
          response = GitlabHook::Sender.new.send(data, {
              channel: receivers[:assignee],
              template_name: 'assignee',
          })
          result = (response and response.instance_of? Net::HTTPOK) ? result : false

          # debug
          puts receivers[:assignee]
          puts response.class
        end
      end

      result
    end
  end
end
