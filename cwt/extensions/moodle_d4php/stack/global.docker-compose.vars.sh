#!/usr/bin/env bash

##
# Stack-specific custom CWT globals for instances using docker-compose.
#
# This file is used during "instance init" to generate the global environment
# variables specific to current project instance.
#
# Latest tag at the time of writing : 1.5.43
# Uses the syntax for Linux (uid 1000 gid 1000).
# See https://github.com/wodby/docker4php/releases
# -> https://github.com/wodby/docker4php/blob/master/.env
#
# @see u_instance_init() in cwt/instance/instance.inc.sh
# @see cwt/utilities/global.sh
# @see cwt/bootstrap.sh
#

global PHP_SNAME "[default]=php"

global APACHE_TAG "[default]='2.4-4.7.1'"
global PHP_TAG "[default]='7.4-4.28.1'"
global MARIADB_TAG "[default]='10.7-3.17.0'"
global ADMINER_TAG "[default]='4-3.18.1'"

# See https://github.com/wodby/apache
global APACHE_LOG_LEVEL "[default]=warn"
global APACHE_VHOST_PRESET "[default]=php"

# See https://github.com/wodby/php
global PHP_FPM_USER "[default]=wodby"
global PHP_FPM_GROUP "[default]=wodby"
