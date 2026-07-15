#!/usr/bin/env bash

##
# Docker stats for the whole local stack services.
#
# @example
#   make stack-stats
#   # Or :
#   cwt/extensions/compose/stack/stats.sh
#

. cwt/bootstrap.sh

containers="$(docker compose ps -q)"

if [[ -z "$containers" ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO: no running containers for current docker compose project." >&2
  echo "-> Aborting (1)." >&2
  echo >&2
  exit 1
fi

# shellcheck disable=SC2086
docker stats $containers
