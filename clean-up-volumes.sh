#!/usr/bin/env bash

set -o pipefail
set -o errexit
set -o nounset
#set -o xtrace

docker inspect -f '{{ .Mounts }}' proxy-slack \
  | grep -Eo '/var/lib/docker/volumes/[A-Za-z0-9/]+[A-Za-z0-9]' \
  | tr ' ' '\n' | xargs -i sudo rm -rf '{}/*'
