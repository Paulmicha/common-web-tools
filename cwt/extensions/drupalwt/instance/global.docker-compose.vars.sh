#!/usr/bin/env bash

##
# Stack-specific CWT globals for instances using docker-compose.
#
# This file is used during "instance init" to generate the global environment
# variables specific to current project instance.
#
# @see u_instance_init() in cwt/instance/instance.inc.sh
# @see cwt/utilities/global.sh
# @see cwt/bootstrap.sh
#

# In order to provide docker-compose stacks presets by Drupal version, we add
# the global DRUPAL_VERSION to the variants used by the docker-compose extension.
# Uses greater deferred value assignment to ensure it gets processed after
# docker-compose's global.vars.sh file.
# @see cwt/extensions/docker-compose/global.vars.sh
# @see u_dc_write_yml() in cwt/extensions/docker-compose/docker-compose.inc.sh
# @see global() + u_global_assign_value() in cwt/utilities/global.sh
global DC_YML_VARIANTS "[value]='$HOST_TYPE $INSTANCE_TYPE d$DRUPAL_VERSION' [index]=1"
