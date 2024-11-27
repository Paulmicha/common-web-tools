#!/usr/bin/env bash

##
# Docker-compose single service "exec" operation.
#
# Action 'service-exec' is shortened to 'se' in Make.
# @see cwt/extensions/docker-compose/global.vars.sh
#
# @example
#   # Execute the value of "$DC_SERVICE_EXEC_FALLBACK" (defaults to 'bash') :
#   make se 'foobar-service'
#   # Or :
#   cwt/extensions/docker-compose/service/exec.sh 'foobar-service'
#
#   # Execute what is passed in arg :
#   make se 'foobar-service' 'ls'
#   # Or :
#   cwt/extensions/docker-compose/service/exec.sh 'foobar-service' 'ls'
#
#   # Domains access check from within containers (requires curl) :
#   make se 'foobar-service' -- $(cwt/escape.sh 'curl -H "Host: foobar.localhost" http://127.0.0.1')
#   # Or :
#   cwt/extensions/docker-compose/service/exec.sh \
#     'foobar-service' \
#     'curl -H "Host: foobar.localhost" http://127.0.0.1'
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

# When nothing is sent in arguments to be executed, default to exec whatever is
# the value of "$DC_SERVICE_EXEC_FALLBACK" (defaults to 'bash').
if [[ -z "$@" && -n "$DC_SERVICE_EXEC_FALLBACK" ]]; then
  docker compose exec "$p_service" "$DC_SERVICE_EXEC_FALLBACK"
else
  docker compose exec "$p_service" $@
fi
