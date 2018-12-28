#!/usr/bin/env bash

##
# Global (env) vars for Drupal 8 apps.
#
# This file is used during "instance init" to generate the global environment
# variables specific to current project instance.
#
# @see u_instance_init() in cwt/instance/instance.inc.sh
# @see cwt/utilities/global.sh
# @see cwt/bootstrap.sh
#

global DRUPAL_CONFIG_SYNC_DIR "[default]=$APP_GIT_WORK_TREE/config/sync"
# TODO [debt] refacto needed for Docker container path conversion.
global DRUPAL_CONFIG_SYNC_DIR_C "[default]=/var/www/html/config/sync"
