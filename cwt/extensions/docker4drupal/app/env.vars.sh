#!/usr/bin/env bash

##
# Global env settings declaration.
#
# This file is dynamically included during stack init. Matching rules and syntax
# are explained in documentation.
# @see cwt/env/README.md
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
