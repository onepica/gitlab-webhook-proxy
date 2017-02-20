#!/usr/bin/env bash
##
# Test inbound input point
#

set -o pipefail
set -o errexit
set -o nounset
#set -o xtrace

# Set magic variables for current file & dir
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__file="${__dir}/$(basename "${BASH_SOURCE[0]}")"
readonly __dir __file

curl localhost:${2:-80}/${1:-inbound} -H "Content-Type: application/json" -X POST -d "$(cat request_stub.json)"
