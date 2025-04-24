#!/usr/bin/env bash

##
# Docker-compose single service "build" operation.
#
# @example
#   make service-build 'arangodb'
#   # Or :
#   cwt/extensions/docker-compose/service/build.sh 'arangodb'
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

echo "Building the '$p_service' service ..."

# TODO [wip] Differenciate single service pre-build hook ?
hook -s 'instance' -p 'pre' -a 'build' -v 'STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE'

docker compose build --no-cache "$p_service"

# TODO [wip] Differenciate single service post-build hook ?
hook -s 'instance' -p 'post' -a 'build' -v 'STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE'

echo "Building the '$p_service' service : done."
echo
