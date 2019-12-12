#!/usr/bin/env bash

##
# Stack-specific custom CWT globals for instances using docker-compose.
#
# This file is used during "instance init" to generate the global environment
# variables specific to current project instance.
#
# Latest tag at the time of writing : 5.4.13
# Uses the syntax for Linux (uid 1000 gid 1000).
# See https://github.com/wodby/docker4drupal/releases
# -> https://github.com/wodby/docker4drupal/blob/5.4.13/.env
#
# @see u_instance_init() in cwt/instance/instance.inc.sh
# @see cwt/utilities/global.sh
# @see cwt/bootstrap.sh
#

global DB_HOST "[default]='mariadb'"
global DB_NAME "[default]='drupal'"
global DB_USER "[default]='drupal'"

global PHP_TAG "[if-DRUPAL_VERSION]=7 [true]='5.6-dev-4.13.18' [false]='7.3-dev-4.13.18' [index]=1"
global MARIADB_TAG "[default]='10.4-3.6.7'"
global NGINX_TAG "[default]='1.17-5.7.2'"
global NGINX_VHOST_PRESET "[default]='drupal$DRUPAL_VERSION' [index]=1"
global REDIS_TAG "[default]='4-3.1.4'"
global ADMINER_TAG "[default]='4-3.7.0'"
global VARNISH_TAG "[default]='4.1-4.3.6'"
