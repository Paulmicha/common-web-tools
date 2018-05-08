#!/usr/bin/env bash

##
# CWT instance stop action.
#
# This generic implementation is meant for stopping this project instance's
# necessary services on host. It supports variants by :
# - PROVISION_USING
# - INSTANCE_TYPE
# - HOST_TYPE
#
# @see hook()
#
# @example
#   cwt/instance/stop.sh
#

. cwt/bootstrap.sh

hook -s 'instance' -a 'stop' -v 'PROVISION_USING INSTANCE_TYPE HOST_TYPE'
