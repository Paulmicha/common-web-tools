#!/usr/bin/env bash

##
# Global (env) vars for drush extension provisionned using docker-compose.
#
# Provides service name (container) for use in bash aliases.
# @see cwt/extensions/drush/cwt/alias.docker-compose.hook.sh
#
# This file is used during "instance init" to generate the global environment
# variables specific to current project instance.
#
# @see u_instance_init() in cwt/instance/instance.inc.sh
# @see cwt/utilities/global.sh
# @see cwt/bootstrap.sh
#

global DRUSH_SERVICE_NAME "[default]=site"
