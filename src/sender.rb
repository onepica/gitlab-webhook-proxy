require 'erb'

require 'ostruct'

# https://github.com/stevenosloan/slack-notifier

require 'slack-notifier'

module GitlabHook
  class Sender
    ##
    # Send message to Slack
    #
    # @param data
    # @param options [Hash] receiver:, username:, :template
    #
    def send(data, options)
      return false if options[:channel].nil?

      slack_client(options).ping(
          load_message data: data, template: options[:template]
      )
    end

    # @param [Hash] options
    # @return [Slack::Notifier]

    def slack_client(options)
      url = options[:webhook_url] || configatron.app.slack.webhook_url
      Slack::Notifier.new url,
                          username: (options[:username] ||
                              configatron.app.slack.bot_username ||
                              'gitlab bot'),
                          channel: (options[:channel] || nil)
    end

    ##
    # Load template message
    #
    # @param [Hash] data
    # @param [String] template
    # @return [String]
    #
    def load_message(data:, template: nil)
      @data = data
      ERB.new(template ? template : fetch_template).result(binding)
    end

    ##
    # Fetch template to send
    #
    # @return [String]
    #
    def fetch_template
      # Due to security reason, it cannot use templates outside until it will be fixed
      # if GitlabHook::Project::config['template']
      #   return GitlabHook::Project::config['template']
      # end

      File.read(
        File.expand_path(configatron.app.path.templates + '/slack/message.erb')
      )
    end
  end
end
