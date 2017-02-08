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
    # @param options [Hash] receiver:, username:
    #
    def send(data, options)
      slack_client(options).ping(
        load_message(data, options)
      )
    end

    # @return [Slack::Notifier]
    def slack_client(options)
      slack_webhook_url='https://hooks.slack.com/services/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'
      Slack::Notifier.new slack_webhook_url, options do
        defaults  username: 'GitLabHook'
      end
    end

    # @return [String]
    def load_message(data, template: nil)
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
        File.expand_path(configatron.app.path.templates + 'slack/message.erb')
      )
    end
  end
end
