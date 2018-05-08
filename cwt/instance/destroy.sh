#!/usr/bin/env bash

##
# CWT instance destroy action.
#
# This generic implementation is meant for deleting all traces of this project
# instance on its host. It supports variants by :
# - PROVISION_USING
# - INSTANCE_TYPE
# - HOST_TYPE
#
# @see hook()
#
# @example
#   cwt/instance/destroy.sh
#

. cwt/bootstrap.sh

hook -s 'instance' -a 'destroy' -v 'PROVISION_USING INSTANCE_TYPE HOST_TYPE'
