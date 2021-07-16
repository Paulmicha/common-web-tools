#!/usr/bin/env bash

##
# Docker-compose single service "rebuild" operation.
#
# @example
#   make service-rebuild 'arangodb'
#   # Or :
#   cwt/extensions/docker-compose/service/rebuild.sh 'arangodb'
#

cwt/extensions/docker-compose/service/rm.sh "$1" \
  && cwt/extensions/docker-compose/service/build.sh "$1" \
  && cwt/instance/start.sh
  # && cwt/extensions/docker-compose/service/create.sh "$1" \
  # && cwt/extensions/docker-compose/service/start.sh "$1"
