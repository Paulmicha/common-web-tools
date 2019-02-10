#!/usr/bin/env bash

##
# Global (env) vars for the 'docker4drupal' CWT extension.
#
# This file is used during "instance init" to generate the global environment
# variables specific to current project instance.
#
# @see u_instance_init() in cwt/instance/instance.inc.sh
# @see cwt/utilities/global.sh
# @see cwt/bootstrap.sh
#

# Default aliases need container names for php and database containers.
# @see cwt/extensions/docker4drupal/cwt/bootstrap.docker-compose.hook.sh
# Redis container name is also necessary for default Drupal settings.
# @see cwt/extensions/docker4drupal/app/drupal_settings.7.tpl.php
global D4D_PHP_SNAME "[default]=php"
global D4D_DB_SNAME "[default]=mariadb"
global D4D_REDIS_SNAME "[default]=redis"

# Make the automatic crontab setup for Drupal cron on local host during 'app
# install' opt-in.
global D4D_USE_CRONTAB "[default]=false"

# [optional] Shorter generated make tasks names.
# @see u_instance_task_name() in cwt/instance/instance.inc.sh
global CWT_MAKE_TASKS_SHORTER "[append]='docker4drupal/d4d'"
