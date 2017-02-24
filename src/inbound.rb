require_relative 'merge_request'
require_relative 'sender'
require_relative 'log_point'

module GitlabHook
  class Inbound
    ##
    # Forward inbound request to a service
    #
    # @return [GitlabHook::Sender]
    #
    def forward(data)
      receivers = GitlabHook::MergeRequest.new(data).match_receivers

      result = true

      if receivers[:merged]
        response = service_transport.send(data, {
            channel: receivers[:merged],
            template_name: 'merged',
        })
        result = (response and response.instance_of? Net::HTTPOK) ? result : false

        log_response(receivers[:merged], response)
      end

      if receivers[:assignee]
        response = service_transport.send(data, {
            channel: receivers[:assignee],
            template_name: 'assignee',
        })
        result = (response and response.instance_of? Net::HTTPOK) ? result : false

        log_response(receivers[:assignee], response)
      end

      if receivers[:team]
        receivers[:team].each do |receiver|
          response = service_transport.send(data, {
              channel: receiver,
              template_name: 'group',
          })
          result = (response and response.instance_of? Net::HTTPOK) ? result : false

          log_response(receiver, response)
        end
      end

      result
    end

    protected

    ##
    # Transport for messages
    #
    # @return [GitlabHook::Sender]
    #
    def service_transport
      GitlabHook::Sender.new
    end

    ##
    # Log result of request
    #
    # @param [string] receiver
    # @param [Net::HTTPOK] response
    # @return self
    #
    def log_response(receiver, response)
      unless response.instance_of? Net::HTTPOK
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
