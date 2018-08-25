#!/usr/bin/env bash

##
# [abstract] Stops this project instance's services on current host.
#
# This script provides an entry point for triggering a specific hook. "Abstract"
# means that CWT core itself doesn't provide any actual implementation for this
# functionality. In order for this script to have any effect, it is necessary
# to use an extension that does.
#
# @example
#   make stop
#   # Or :
#   cwt/instance/stop.sh
#

. cwt/bootstrap.sh

hook -s 'instance' -a 'stop' -v 'PROVISION_USING HOST_TYPE INSTANCE_TYPE'
