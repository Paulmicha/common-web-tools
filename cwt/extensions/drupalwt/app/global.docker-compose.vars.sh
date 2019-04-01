#!/usr/bin/env bash

##
# Drupal-related global (env) vars for instances using docker-compose.
#
# Convention : variables suffixed with *_C are containers paths.
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
global APP_DOCROOT_C "[default]=/var/www/html"

global DRUPAL_FILES_DIR_C "[default]=sites/default/files"

# These require matching volumes in docker-compose.yml for the 'php' container.
global DRUPAL_TMP_DIR_C "[default]='/var/drupal-tmp'"
global DRUPAL_PRIVATE_DIR_C "[default]='/var/drupal-private'"

# Default settings for commonly used Redis cache backend.
global REDIS_CLIENT_HOST "${DWT_REDIS_SNAME:=redis}"
global REDIS_CLIENT_PORT '6379'

# Drupal settings specific to version 8+.
global DRUPAL_CONFIG_SYNC_DIR_C "[ifnot-DRUPAL_VERSION]=7 [default]=/var/www/config/sync"
