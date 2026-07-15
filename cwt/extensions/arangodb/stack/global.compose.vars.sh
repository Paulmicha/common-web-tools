#!/usr/bin/env bash

##
# Stack-specific custom CWT globals for instances using docker-compose.
#
# See https://hub.docker.com/_/arangodb/
#
# This file is used during "instance init" to generate the global environment
# variables specific to current project instance.
#
# @see u_instance_init() in cwt/instance/instance.inc.sh
# @see cwt/utilities/global.sh
# @see cwt/bootstrap.sh
#

global ARANGODB_TAG "[default]='3.7.12'"
