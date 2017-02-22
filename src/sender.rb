require 'erb'

require 'ostruct'

# https://github.com/stevenosloan/slack-notifier

require 'slack-notifier'

module GitlabHook
  class Sender
    @default_template_name = 'default'

    ##
    # Send message to Slack
    #
    # @param data
    # @param options [Hash] receiver:, username:, :template
    #
    def send(data, options)
      return false if options[:channel].nil?

      slack_client(options).ping(
          load_message data: data, options: options
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
                          channel: options[:channel]
    end

    ##
    # Load template message
    #
    # @param [Hash] data
    # @param [Hash] options
    # @return [String]
    #
    def load_message(data:, options: nil)
      @data = data
      ERB.new(options[:template] || fetch_template(options[:template_name])).result(binding)
    end

    ##
    # Fetch template to send
    #
    # @return [String]
    #
    def fetch_template(template_name = nil)
      # Due to security reason, it cannot use templates outside until it will be fixed
      # if GitlabHook::Project::config['template']
      #   return GitlabHook::Project::config['template']
      # end

      if template_name.nil?
        template_name = @default_template_name
      else
        validate_template_name template_name
      end

      File.read(
          File.expand_path(
              configatron.app.path.templates + '/slack/message/' +
                  template_name + '.erb')
      )
    end

    def default_template_name=(name)
      validate_template_name(name)

      @default_template_name = name

      self
    end

    def validate_template_name(name)
      until name =~ /^[A-z0-9_.-]+$/
        raise 'Invalid template name.'
      end
      until File.exist? configatron.app.path.templates + '/slack/message/' + name + '.erb'
        raise 'Template file does not exist.'
      end

      true
    end

    def user(id)
      GitlabHook::User.new(id)
    end
  end
end
