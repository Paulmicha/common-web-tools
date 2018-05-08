#!/usr/bin/env bash

##
# Global (env) vars for Drupal 8 apps.
#
# This file is automatically loaded during "instance init" to generate a single
# script :
#
# cwt/env/current/global.vars.sh
#
# That script file will contain declarations for every global variables found in
# this project instance as readonly. It is git-ignored and loaded on every
# bootstrap - if it exists, that is if "instance init" was already launched once
# in current project instance.
#
# Unless the "instance init" command is set to bypass prompts, every call to
# global() will prompt for confirming or replacing default values or for simply
# entering a value if no default is declared.
#
# @see cwt/instance/instance.inc.sh
# @see cwt/utilities/global.sh
# @see cwt/bootstrap.sh
#

global DRUPAL_CONFIG_SYNC_DIR "[default]=$APP_GIT_WORK_TREE/config/sync"

global WRITEABLE_DIRS "[append]=$APP_GIT_WORK_TREE/config"
global WRITEABLE_DIRS "[append]=$APP_GIT_WORK_TREE/vendor"

global WRITEABLE_FILES "[append]=$APP_GIT_WORK_TREE/composer.json"
global WRITEABLE_FILES "[append]=$APP_GIT_WORK_TREE/composer.lock"
global WRITEABLE_FILES "[append]=$APP_GIT_WORK_TREE/vendor/autoload.php"
