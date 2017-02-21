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

#bundle install --path ${__dir}/bundle_install
bundle install || bundle update
