require 'configatron'

c = configatron.app
c.gitlab.endpoint             = ENV['APP_GITLAB_ENDPOINT']
c.gitlab.super.private_token  = ENV['APP_GITLAB_PRIVATE_TOKEN']
c.slack.webhook_url           = ENV['APP_SLACK_WEBHOOK']
c.web.port                    = ENV['APP_WEB_PORT'] ? ENV['APP_WEB_PORT'] : 8088
