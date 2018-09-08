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

  docker-compose pull
  docker-compose up -d --remove-orphans

  # TODO [workaround] Sometimes services are not immediately available, so we add
  # some delay in case this call is part of chained operations.
  sleep 2

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

  docker-compose stop

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

  docker-compose build --no-cache

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

  docker-compose down --remove-orphans

  echo "Destroying $INSTANCE_DOMAIN (stops and removes containers, networks, volumes, and images) : done."
  echo
}
