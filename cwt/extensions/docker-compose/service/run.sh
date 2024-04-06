#!/usr/bin/env bash

##
# Docker-compose single service "run" operation.
#
# @example
#   make service-run 'arangodb' 'bash'
#   # Or :
#   cwt/extensions/docker-compose/service/run.sh 'arangodb' 'bash'
#

. cwt/bootstrap.sh

p_service="$1"

if [[ -z "$p_service" ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO: service name is required." >&2
  echo "-> Aborting (1)." >&2
  echo >&2
  exit 1
fi

shift 1

docker compose run "$p_service" $@
