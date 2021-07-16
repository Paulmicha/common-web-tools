#!/usr/bin/env bash

##
# Docker-compose single service "start" operation.
#
# @example
#   make service-start 'arangodb'
#   # Or :
#   cwt/extensions/docker-compose/service/start.sh 'arangodb'
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

echo "Starting the '$p_service' service ..."

# TODO [wip] Differenciate single service pre-start hook ?
hook -s 'instance' -p 'pre' -a 'start' -v 'PROVISION_USING HOST_TYPE INSTANCE_TYPE'

docker-compose start "$p_service"

# TODO [wip] Differenciate single service post-start hook ?
hook -s 'instance' -p 'post' -a 'start' -v 'PROVISION_USING HOST_TYPE INSTANCE_TYPE'

echo "Starting the '$p_service' service : done."
echo

# Create an opportunity for containers like databases to wait until their
# service(s) are ready / accept connections. Examples :
# See https://github.com/wodby/docker4drupal/blob/master/tests/8/run.sh
# See https://github.com/wodby/mariadb/blob/master/10/bin/actions.mk
# See https://github.com/wodby/alpine/blob/master/bin/wait_for
# This needs to happen before the "post-start" hook, for some implementations
# may depend on this check.
# @see cwt/instance/start.sh
hook -s 'instance' -a 'wait_for' -v 'PROVISION_USING HOST_TYPE INSTANCE_TYPE'
