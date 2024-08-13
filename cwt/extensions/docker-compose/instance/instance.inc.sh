#!/usr/bin/env bash

##
# Docker-compose instance-related utility functions.
#
# This file is sourced during core CWT bootstrap.
# @see cwt/bootstrap.sh
#
# Convention : functions names are all prefixed by "u" (for "utility").
#

##
# Pulls (if needed) images & starts containers.
#
# @see https://github.com/wodby/docker4drupal/blob/master/docker.mk
#
u_dc_instance_start() {
  echo "Starting $INSTANCE_DOMAIN containers ..."

  docker compose pull

  if [[ $? -ne 0 ]]; then
    echo >&2
    echo "Error in u_dc_instance_start() - $BASH_SOURCE line $LINENO : 'docker compose pull' exited with non-zero status." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    exit 1
  fi

  docker compose up -d --remove-orphans

  if [[ $? -ne 0 ]]; then
    echo >&2
    echo "Error in u_dc_instance_start() - $BASH_SOURCE line $LINENO : 'docker compose up -d --remove-orphans' exited with non-zero status." >&2
    echo "-> Aborting (2)." >&2
    echo >&2
    exit 2
  fi

  # Create an opportunity for containers like databases to wait until their
  # service(s) are ready / accept connections. Examples :
  # See https://github.com/wodby/docker4drupal/blob/master/tests/8/run.sh
  # See https://github.com/wodby/mariadb/blob/master/10/bin/actions.mk
  # See https://github.com/wodby/alpine/blob/master/bin/wait_for
  # This needs to happen before the "post-start" hook, for some implementations
  # may depend on this check.
  # @see cwt/instance/start.sh
  hook -s 'instance' -a 'wait_for' -v 'PROVISION_USING HOST_TYPE INSTANCE_TYPE'

  echo "Starting $INSTANCE_DOMAIN containers : done."
  echo
}

##
# Stops containers.
#
# @see https://github.com/wodby/docker4drupal/blob/master/docker.mk
#
u_dc_instance_stop() {
  echo "Stopping $INSTANCE_DOMAIN containers ..."

  docker compose stop

  echo "Stopping $INSTANCE_DOMAIN containers : done."
  echo
}

##
# Builds containers.
#
# @see https://github.com/wodby/docker4drupal/blob/master/docker.mk
#
u_dc_instance_build() {
  echo "Building $INSTANCE_DOMAIN containers ..."

  docker compose build --no-cache

  echo "Building $INSTANCE_DOMAIN containers : done."
  echo
}

##
# Deletes containers and remove networks (except if external).
#
# @see https://docs.docker.com/compose/reference/down/
#
u_dc_instance_destroy() {
  echo "Destroying $INSTANCE_DOMAIN (stops and removes containers, networks, volumes, and images) ..."

  docker compose down --remove-orphans --volumes

  echo "Destroying $INSTANCE_DOMAIN (stops and removes containers, networks, volumes, and images) : done."
  echo
}
