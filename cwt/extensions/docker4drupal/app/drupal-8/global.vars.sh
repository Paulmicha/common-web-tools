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

global WRITEABLE_DIRS "[append]=$APP_GIT_WORK_TREE/config"
global WRITEABLE_DIRS "[append]=$APP_GIT_WORK_TREE/vendor"

global WRITEABLE_FILES "[append]=$APP_GIT_WORK_TREE/composer.json"
global WRITEABLE_FILES "[append]=$APP_GIT_WORK_TREE/composer.lock"
global WRITEABLE_FILES "[append]=$APP_GIT_WORK_TREE/vendor/autoload.php"
