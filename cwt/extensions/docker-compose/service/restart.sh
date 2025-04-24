#!/usr/bin/env bash

##
# Docker-compose single service "restart" operation.
#
# @example
#   make service-restart 'arangodb'
#   # Or :
#   cwt/extensions/docker-compose/service/restart.sh 'arangodb'
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

echo "Restarting the '$p_service' service ..."

docker compose restart "$p_service"

echo "Restarting the '$p_service' service : done."
echo

# Create an opportunity for containers like databases to wait until their
# service(s) are ready / accept connections. Examples :
# See https://github.com/wodby/docker4drupal/blob/master/tests/8/run.sh
# See https://github.com/wodby/mariadb/blob/master/10/bin/actions.mk
# See https://github.com/wodby/alpine/blob/master/bin/wait_for
# This needs to happen before the "post-start" hook, for some implementations
# may depend on this check.
# @see cwt/instance/start.sh
hook -s 'instance' -a 'wait_for' -v 'STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE'
