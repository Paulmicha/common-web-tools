#!/usr/bin/env bash

##
# Docker-compose single service "rm" operation.
#
# @example
#   make service-rm 'arangodb'
#   # Or :
#   cwt/extensions/docker-compose/service/rm.sh 'arangodb'
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

echo "Removing the '$p_service' service ..."

docker compose rm -fsv "$p_service"

echo "Removing the '$p_service' service : done."
echo
