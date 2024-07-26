#!/usr/bin/env bash

##
# Docker-compose reinit operation.
#
# Only regenerates the docker-compose.yml file(s).
#
# @see cwt/extensions/docker-compose/global.vars.sh
# @see u_dc_write_yml() in cwt/extensions/docker-compose/docker-compose.inc.sh
#
# @example
#   # To apply changes made to local dev stack :
#   make stack-reinit
#   make restart
#   # Or :
#   cwt/extensions/docker-compose/stack/reinit.sh
#   cwt/instance/restart.sh
#

. cwt/bootstrap.sh

echo "Reinit docker-compose stack ..."

case "$DC_MODE" in 'generate')
  u_dc_write_yml
esac

echo "Reinit docker-compose stack : done."
echo
