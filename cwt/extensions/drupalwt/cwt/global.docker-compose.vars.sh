#!/usr/bin/env bash

##
# Global (env) vars for drupalwt extension provisionned using docker-compose.
#
# Provides service names (containers) for use in bash aliases.
# @see cwt/extensions/drupalwt/cwt/bootstrap.docker-compose.hook.sh
#
# This file is used during "instance init" to generate the global environment
# variables specific to current project instance.
#
# @see u_instance_init() in cwt/instance/instance.inc.sh
# @see cwt/utilities/global.sh
# @see cwt/bootstrap.sh
#

# Redis container name is also necessary for default Drupal settings.
# @see cwt/extensions/drupalwt/app/drupal_settings.7.tpl.php
global PHP_SNAME "[default]=php"
global REDIS_SNAME "[default]=redis"
