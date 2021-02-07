#!/usr/bin/env bash

##
# Stack-specific custom CWT globals for instances using docker-compose.
#
# This file is used during "instance init" to generate the global environment
# variables specific to current project instance.
#
# Latest tag at the time of writing : 5.4.25
# Uses the syntax for Linux (uid 1000 gid 1000).
# See https://github.com/wodby/docker4drupal/releases
# -> https://github.com/wodby/docker4drupal/blob/5.4.25/.env
#
# @see u_instance_init() in cwt/instance/instance.inc.sh
# @see cwt/utilities/global.sh
# @see cwt/bootstrap.sh
#

global PHP_SNAME "[default]=php"
global REDIS_SNAME "[default]=redis"
global SOLR_SNAME "[default]=solr"

global PHP_TAG "[if-DRUPAL_VERSION]=7 [true]='5.6-dev-4.13.18' [false]='7.4-dev-4.22.0' [index]=1"
global MARIADB_TAG "[default]='10.5-3.10.1'"
global NGINX_TAG "[default]='1.19-5.11.1'"
global NGINX_VHOST_PRESET "[default]='drupal$DRUPAL_VERSION' [index]=1"
global REDIS_TAG "[default]='6-3.5.0'"
global ADMINER_TAG "[default]='4-3.14.0'"
global SOLR_TAG "[default]='8-4.8.0'"
global TIKA_TAG "[default]='1.25-full'"
global SOLR_CONFIG_SET "[default]='search_api_solr_4.1.9'"
global VARNISH_TAG "[default]='6.0-4.5.1'"
