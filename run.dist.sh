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

export APP_SLACK_WEBHOOK='https://hooks.slack.com/services/QWEQWE/QWEQWE/QWEQWEQWEQWEQWEQWE'
export APP_GITLAB_PRIVATE_TOKEN='QWEQWEQWEQWEQWEQWE'
export APP_GITLAB_ENDPOINT='https://git.example.com/api/v3'
export APP_WEB_PORT=8088

ruby ${__dir}/server.rb -o 0.0.0.0
