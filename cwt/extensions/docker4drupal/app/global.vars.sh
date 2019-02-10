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

# Path to public web directory (where index resides) inside web server + php
# containers. Used in docker-compose.yml file.
global DRUPAL_PUBLIC_DOCROOT "[default]=/var/www/html"

global DRUPAL_VERSION "[default]=8"

global DRUPAL_LOCAL_SETTINGS "[default]=$APP_DOCROOT/sites/default/settings.local.php"

# TODO find a way to handle relative path inside containers.
# -> Meanwhile, store both separately (host path + container path).
# Convention : variables suffixed with *_C are containers paths.

global DRUPAL_FILES_DIR "[default]=$APP_DOCROOT/sites/default/files"
global DRUPAL_FILES_DIR_C "[default]=sites/default/files"

# These require volumes in docker-compose.yml for the 'php' container.
global DRUPAL_TMP_DIR "[default]=$PROJECT_DOCROOT/data/tmp"
global DRUPAL_TMP_DIR_C "[default]='/var/drupal-tmp'"
global DRUPAL_PRIVATE_DIR "[default]=$PROJECT_DOCROOT/data/private"
global DRUPAL_PRIVATE_DIR_C "[default]='/var/drupal-private'"

# TODO [evol] Persist across local rebuilds (registry) ?
global DRUPAL_HASH_SALT "$(u_str_random)"

# Default settings for commonly used Redis cache backend.
global REDIS_CLIENT_HOST 'redis'
global REDIS_CLIENT_PORT '6379'

# Drupal settings specific to version 8.
# TODO [evol] evaluate globals dependency (priority) to order values assignation.
global DRUPAL_CONFIG_SYNC_DIR "[default]=${APP_GIT_WORK_TREE:=$APP_DOCROOT}/config/sync"
# TODO [debt] refacto needed for Docker container path conversion.
global DRUPAL_CONFIG_SYNC_DIR_C "[default]=/var/www/html/config/sync"

# Filesystem permissions related to the Drupal app.
global WRITEABLE_DIRS "[append]=$DRUPAL_FILES_DIR"
global WRITEABLE_DIRS "[append]=$DRUPAL_TMP_DIR"
global WRITEABLE_DIRS "[append]=$DRUPAL_PRIVATE_DIR"
global PROTECTED_FILES "[append]=$APP_DOCROOT/sites/default/settings.php"
global PROTECTED_FILES "[append]=$DRUPAL_LOCAL_SETTINGS"

# Optional crontab setup on host during 'app install' : defines frequence,
# defaults to every 20min.
global DRUPAL_CRON_FREQ "[default]='*/20 * * * *'"
