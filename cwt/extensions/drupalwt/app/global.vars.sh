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

global DRUPAL_VERSION "[default]=8"

global DRUPAL_LOCAL_SETTINGS "[default]=$APP_DOCROOT/sites/default/settings.local.php"

global DRUPAL_FILES_DIR "[default]=$APP_DOCROOT/sites/default/files"
global DRUPAL_TMP_DIR "[default]=$PROJECT_DOCROOT/data/tmp"
global DRUPAL_PRIVATE_DIR "[default]=$PROJECT_DOCROOT/data/private"

# TODO [evol] Persist across local rebuilds (registry) ?
global DRUPAL_HASH_SALT "$(u_str_random)"

# Default settings for commonly used Redis cache backend.
# Workaround globals overriding order (specific may get called before).
# @see cwt/extensions/drupalwt/app/global.docker-compose.vars.sh
global REDIS_CLIENT_HOST "[if-REDIS_CLIENT_HOST]='' [default]=localhost"
global REDIS_CLIENT_PORT '6379'

# Drupal settings specific to version 8+.
# TODO [evol] evaluate globals dependency (priority) to order values assignation.
global DRUPAL_CONFIG_SYNC_DIR "[ifnot-DRUPAL_VERSION]=7 [default]=${APP_GIT_WORK_TREE:=$APP_DOCROOT}/config/sync"

# Filesystem permissions related to the Drupal app.
global WRITEABLE_DIRS "[append]=$DRUPAL_FILES_DIR"
global WRITEABLE_DIRS "[append]=$DRUPAL_TMP_DIR"
global WRITEABLE_DIRS "[append]=$DRUPAL_PRIVATE_DIR"
global EXECUTABLE_DIRS "[ifnot-DRUPAL_VERSION]=7 [append]=${APP_GIT_WORK_TREE:=$APP_DOCROOT}/vendor"
global PROTECTED_FILES "[append]=$APP_DOCROOT/sites/default/settings.php"
global PROTECTED_FILES "[append]=$DRUPAL_LOCAL_SETTINGS"

# Optional crontab setup on host during 'app install' : defines frequence,
# defaults to every 20min.
global DRUPAL_CRON_FREQ "[default]='*/20 * * * *'"
