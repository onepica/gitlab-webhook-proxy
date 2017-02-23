require 'configatron'
require 'yaml'

require_relative 'merge_request'

require_relative 'sender'
require_relative 'project'

require_relative 'error'
require_relative 'log_point'

module GitlabHook
  class Inbound
    def forward(data)
      unless Project::action_allowed? data['object_kind'], data['object_attributes']['action']
        puts "action not allowed: #{data['object_kind']}, #{data['object_attributes']['action']}"
        return false
      end

      receivers = GitlabHook::MergeRequest.new(data).match_receivers

      result = true

      if receivers[:assignee]
        response = GitlabHook::Sender.new.send(data, {
            channel: receivers[:assignee],
            template_name: 'assignee',
        })
        result = (response and response.instance_of? Net::HTTPOK) ? result : false

        log(receivers[:assignee], response)
      end

      if receivers[:team]
        receivers[:team].each do |receiver|
          response = GitlabHook::Sender.new.send(data, {
              channel: receiver,
              template_name: 'group',
          })
          result = (response and response.instance_of? Net::HTTPOK) ? result : false

          log(receiver, response)
        end
      end

      result
    end

    protected

    ##
    # Log result of request
    #
    # @param [string] receiver
    # @param [Net::HTTPOK] response
    # @return self
    #
    def log(receiver, response)
      unless response.instance_of? Net::HTTPOK.
          LogPoint::write 'Cannot deliver to ' + receiver, 'slack_messages', Logger::WARN
      end
      LogPoint::write(
        sprintf('Processed %s with status %s.', receiver, response.to_s),
        'inbound',
        Logger::INFO
      )

      self
    end
  end
end
