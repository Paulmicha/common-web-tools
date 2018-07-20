#!/usr/bin/env bash

##
# Builds this project instance's necessary services.
#
# @example
#   make instance-build
#   cwt/extensions/docker-compose/instance/build.sh
#

. cwt/bootstrap.sh

hook -s 'instance app' -a 'build' -v 'PROVISION_USING HOST_TYPE INSTANCE_TYPE'
