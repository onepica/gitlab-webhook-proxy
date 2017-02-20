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
      message = load_message data: data, options[:template]
      slack_client(options).ping(message)
    end

    # @param [Hash] options
    # @return [Slack::Notifier]
    def slack_client(options)
        Slack::Notifier.new options[:webhook_url] || configatron.app.slack.webhook_url,
                            options do
        defaults  username: 'GitLabHook'
      end
    end

    # @param [Hash] data
    # @param [String] template
    # @return [String]
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
      if GitlabHook::Project::config['template']
        return GitlabHook::Project::config['template']
      end

      File.read(
        File.expand_path(configatron.app.path.templates + '/slack/message.erb')
      )
    end
  end
end
