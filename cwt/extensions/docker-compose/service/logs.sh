#!/usr/bin/env bash

##
# Reads single Docker-compose service logs.
#
# @example
#   make service-logs 'arangodb'
#   # Or :
#   cwt/extensions/docker-compose/service/logs.sh 'arangodb'
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

docker compose logs "$p_service"
