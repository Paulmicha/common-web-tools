#!/usr/bin/env bash

##
# Apply changes to the compose stack services.
#
# (Re)generate the git-ignored compose files + restart all stack services.
#
# @example
#   make compose-update
#   # Or :
#   cwt/extensions/docker-compose/compose/update.sh
#

. cwt/extensions/docker-compose/compose/write.sh
. cwt/instance/restart.sh
