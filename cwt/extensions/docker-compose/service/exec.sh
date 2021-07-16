#!/usr/bin/env bash

##
# Docker-compose single service "exec" operation.
#
# @example
#   make service-exec 'arangodb' 'bash'
#   # Or :
#   cwt/extensions/docker-compose/service/exec.sh 'arangodb' 'bash'
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

docker-compose exec "$p_service" $@
