require 'configatron'

c                            = configatron.app
c.gitlab.endpoint            = ENV['APP_GITLAB_ENDPOINT']
c.gitlab.super.private_token = ENV['APP_GITLAB_PRIVATE_TOKEN']
c.slack.webhook_url          = ENV['APP_SLACK_WEBHOOK']
c.slack.bot_username         = ENV['APP_SLACK_BOT_USERNAME'] || 'GitLabBot'
c.web.port                   = ENV['APP_WEB_PORT'] || 8088
c.web.ip                     = ENV['APP_WEB_IP'] || '0.0.0.0'
c.web.host                   = ENV['APP_WEB_HOST'] || 'gitlab-proxy.cc'
c.web.inbound_token          = ENV['APP_INBOUND_TOKEN'] || ''
