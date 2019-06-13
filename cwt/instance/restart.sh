#!/usr/bin/env bash

##
# Triggers a generic 'restart' operation for this project instance.
#
# This merely chains 'stop' and 'start' actions.
# @see cwt/instance/stop.sh
# @see cwt/instance/start.sh
#
# @example
#   make restart
#   # Or :
#   cwt/instance/restart.sh
#

. cwt/instance/stop.sh
. cwt/instance/start.sh
