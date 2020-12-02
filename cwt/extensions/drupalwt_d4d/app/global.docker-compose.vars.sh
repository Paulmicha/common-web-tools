#!/usr/bin/env bash

##
# Drupal-related global (env) vars for instances using docker-compose.
#
# Convention : variables suffixed with *_C are containers paths used in
# docker-compose.yml file.
#
# This file is used during "instance init" to generate the global environment
# variables specific to current project instance.
#
# @see u_instance_init() in cwt/instance/instance.inc.sh
# @see cwt/utilities/global.sh
# @see cwt/bootstrap.sh
#

global APP_DOCROOT_C "[default]=/var/www/html"
global SERVER_DOCROOT_C "[if-SERVER_DOCROOT]='$APP_DOCROOT/docroot' [true]=/var/www/html/docroot [false]=/var/www/html/web [index]=1"

global DRUPAL_FILES_DIR_C "[default]=sites/default/files"
global DRUPAL_TMP_DIR_C "[default]='/mnt/files/tmp'"
global DRUPAL_PRIVATE_DIR_C "[default]='/mnt/files/private'"
global DRUPAL_CONFIG_SYNC_DIR_C "[ifnot-DRUPAL_VERSION]=7 [default]=$APP_DOCROOT_C/config/sync [index]=1"

global REDIS_CLIENT_HOST "[value]=${REDIS_SNAME:=redis} [index]=1"
