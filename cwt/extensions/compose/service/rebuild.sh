#!/usr/bin/env bash

##
# Docker-compose single service "rebuild" operation.
#
# @example
#   make service-rebuild 'arangodb'
#   # Or :
#   cwt/extensions/compose/service/rebuild.sh 'arangodb'
#

cwt/extensions/compose/service/rm.sh "$1" \
  && cwt/extensions/compose/service/build.sh "$1" \
  && cwt/instance/start.sh
  # && cwt/extensions/compose/service/create.sh "$1" \
  # && cwt/extensions/compose/service/start.sh "$1"
