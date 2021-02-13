#!/usr/bin/env bash

##
# Global (env) vars for drupalwt apps.
#
# This file is used during "instance init" to generate the global environment
# variables specific to current project instance.
#
# @see u_instance_init() in cwt/instance/instance.inc.sh
# @see cwt/utilities/global.sh
# @see cwt/bootstrap.sh
#

global DRUPAL_VERSION "[default]=9"
global DRUPAL_SETTINGS_FILE "[default]=$SERVER_DOCROOT/sites/default/settings.php"
global DRUPAL_SETTINGS_LOCAL_FILE "[default]=$SERVER_DOCROOT/sites/default/settings.local.php"
global DRUPAL_FILES_DIR "[default]=$SERVER_DOCROOT/sites/default/files"
global DRUPAL_TMP_DIR "[default]=$PROJECT_DOCROOT/data/tmp"
global DRUPAL_PRIVATE_DIR "[default]=$PROJECT_DOCROOT/data/private"
global DRUPAL_CONFIG_SYNC_DIR "[ifnot-DRUPAL_VERSION]=7 [default]=$APP_DOCROOT/config/sync"
global DRUPAL_HASH_SALT "$(u_str_random 74)"

global DWT_COMPOSER_INSTALL "[ifnot-DRUPAL_VERSION]=7 [default]='yes' [help]='Determines if composer is used to manage dependencies, i.e. if the command “composer install” must be run during app install by default.'"

global REDIS_CLIENT_HOST "[default]=localhost [help]='Commonly used Redis cache backend settings are included by default.'"
global REDIS_CLIENT_PORT '6379'

# Filesystem permissions related to the Drupal app.
global WRITEABLE_DIRS "[append]=$DRUPAL_FILES_DIR"
global WRITEABLE_DIRS "[append]=$DRUPAL_TMP_DIR"
global WRITEABLE_DIRS "[append]=$DRUPAL_PRIVATE_DIR"
global EXECUTABLE_DIRS "[ifnot-DRUPAL_VERSION]=7 [append]=$APP_DOCROOT/vendor"
global PROTECTED_FILES "[append]=$DRUPAL_SETTINGS_FILE"
global PROTECTED_FILES "[append]=$DRUPAL_SETTINGS_LOCAL_FILE"
