#!/usr/bin/env bash

##
# (Re)generate the git-ignored compose files.
#
# @example
#   make compose-write
#   # Or :
#   cwt/extensions/compose/compose/write.sh
#

. cwt/bootstrap.sh

case "$DC_MODE" in 'generate')
  # @see cwt/extensions/compose/compose.inc.sh
  u_dc_write_yml
esac
