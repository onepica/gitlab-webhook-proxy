#!/usr/bin/env bash

set -o pipefail
set -o errexit
set -o nounset
#set -o xtrace

# Set magic variables for current file & dir
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__file="${__dir}/$(basename "${BASH_SOURCE[0]}")"
readonly __dir __file

export DOCKER_ENV_NAME=dev-

if [ ! -f ${__dir}/dev-app.env ]; then
    echo 'error: Please create file '${__dir}/dev-app.env' with ENV variables.'
    exit 2
fi

docker-compose --file ${__dir}/docker-compose.yml up
