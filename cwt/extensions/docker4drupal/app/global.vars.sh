#!/usr/bin/env bash

##
# Global (env) vars for docker4drupal apps.
#
# This file is used during "instance init" to generate the global environment
# variables specific to current project instance.
#
# @see u_instance_init() in cwt/instance/instance.inc.sh
# @see cwt/utilities/global.sh
# @see cwt/bootstrap.sh
#

global DRUPAL_VERSION "[default]=8"
global DRUPAL_CRON_FREQ "[default]='*/20 * * * *'"

global DRUPAL_LOCAL_SETTINGS "[default]=$APP_DOCROOT/sites/default/settings.local.php"

# TODO find a way to handle relative path inside containers.
# -> Meanwhile, store both separately (host path + container path).

global DRUPAL_FILES_DIR "[default]=$APP_DOCROOT/sites/default/files"
global DRUPAL_FILES_DIR_C "[default]=sites/default/files"

# These require volumes in docker-compose.yml for the 'php' container.
global DRUPAL_TMP_DIR "[default]=$PROJECT_DOCROOT/data/tmp"
global DRUPAL_TMP_DIR_C "[default]='/var/drupal-tmp'"
global DRUPAL_PRIVATE_DIR "[default]=$PROJECT_DOCROOT/data/private"
global DRUPAL_PRIVATE_DIR_C "[default]='/var/drupal-private'"

# TODO [evol] Persist across local rebuilds (registry) ?
global DRUPAL_HASH_SALT "$(u_str_random)"

global WRITEABLE_DIRS "[append]=$DRUPAL_FILES_DIR"
global WRITEABLE_DIRS "[append]=$DRUPAL_TMP_DIR"
global WRITEABLE_DIRS "[append]=$DRUPAL_PRIVATE_DIR"

global PROTECTED_FILES "[append]=$APP_DOCROOT/sites/default/settings.php"
global PROTECTED_FILES "[append]=$DRUPAL_LOCAL_SETTINGS"

# Conditionally load Drupal version-specific globals.
if [ -f "cwt/extensions/docker4drupal/app/drupal-${DRUPAL_VERSION}/global.vars.sh" ]; then
  . "cwt/extensions/docker4drupal/app/drupal-${DRUPAL_VERSION}/global.vars.sh"
fi
