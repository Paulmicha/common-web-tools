#!/usr/bin/env bash

##
# Docker-compose single service "create" operation.
#
# TODO deprecated
#
# @example
#   make service-create 'arangodb'
#   # Or :
#   cwt/extensions/docker-compose/service/create.sh 'arangodb'
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

echo "Creating the '$p_service' service container ..."

docker-compose create "$p_service"

echo "Creating the '$p_service' service container : done."
echo
