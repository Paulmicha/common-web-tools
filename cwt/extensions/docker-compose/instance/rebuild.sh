#!/usr/bin/env bash

##
# Rebuilds this project instance's necessary services.
#
# @example
#   make instance-rebuild
#   cwt/extensions/docker-compose/instance/rebuild.sh
#

. cwt/bootstrap.sh

hook -s 'instance app' -a 'rebuild' -v 'PROVISION_USING HOST_TYPE INSTANCE_TYPE'
