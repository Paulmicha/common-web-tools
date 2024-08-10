#!/usr/bin/env bash

##
# Implements hook -s 'instance' -a 'uninit'.
#
# Cleans up generated remote instance definitions.
# @see cwt/instance/uninit.sh
#
# @example
#   make uninit
#   # Or :
#   cwt/instance/uninit.sh
#

# @see cwt/extensions/remote/remote.inc.sh
u_remote_purge_instances
