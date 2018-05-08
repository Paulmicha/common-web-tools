#!/usr/bin/env bash

##
# Global (env) vars for docker4drupal apps.
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

global DRUPAL_VERSION "[default]=8"

global DRUPAL_LOCAL_SETTINGS "[default]=$APP_DOCROOT/sites/default/settings.local.php"

# TODO find a way to handle relative path inside containers.
# -> Meanwhile, store both separately (host path + container path).

global DRUPAL_FILES_DIR "[default]=$APP_DOCROOT/sites/default/files"
global DRUPAL_FILES_DIR_C "[default]=sites/default/files"

global DRUPAL_TMP_DIR "[default]=$APP_GIT_WORK_TREE/tmp"
global DRUPAL_TMP_DIR_C "[default]='/var/www/html/tmp'"

global DRUPAL_PRIVATE_DIR "[default]=$APP_GIT_WORK_TREE/private"
global DRUPAL_PRIVATE_DIR_C "[default]='/var/www/html/private'"

global WRITEABLE_DIRS "[append]=$DRUPAL_FILES_DIR"
global WRITEABLE_DIRS "[append]=$DRUPAL_TMP_DIR"
global WRITEABLE_DIRS "[append]=$DRUPAL_PRIVATE_DIR"

global PROTECTED_FILES "[append]=$DRUPAL_LOCAL_SETTINGS"

# Conditionally load Drupal version-specific globals.
if [ -f "drupal-${DRUPAL_VERSION}/env.vars.sh" ]; then
  . "drupal-${DRUPAL_VERSION}/env.vars.sh"
fi
