#!/usr/bin/env bash

set -o pipefail
set -o errexit
set -o nounset
#set -o xtrace

# Batch Installation

# Set magic variables for current file & dir
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__file="${__dir}/$(basename "${BASH_SOURCE[0]}")"
readonly __dir __file

# Webhook URL from slack which will be used for sending messages
export APP_SLACK_WEBHOOK='https://hooks.slack.com/services/QWEQWE/QWEQWE/QWEQWEQWEQWEQWEQWE'
# A super user's GitLab private token
export APP_GITLAB_PRIVATE_TOKEN='QWEQWEQWEQWEQWEQWE'
# GitLab API URL
export APP_GITLAB_ENDPOINT='https://git.example.com/api/v3'
# App port
export APP_WEB_PORT=8088
# App hostname
export APP_WEB_HOST='gitlab-proxy.cc'

# for production
bundle exec ruby ${__dir}/app.rb
# for development
#rerun "bundle exec ruby ${__dir}/app.rb"
