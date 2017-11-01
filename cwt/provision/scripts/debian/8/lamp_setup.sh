#!/bin/bash

##
# LAMP server quick setup script for local dev (Drupal / Symfony friendly).
#
# Tested on Debian 8.7 "Jessie"
# @timestamp 2017/07/02 17:49:15
#
# Note : there is no dependency management - all "stacks" setup scripts like
# this one are to be manually edited.
#
# TODO figure out how to handle optional extensions, like :
# - application-specific dependencies (e.g. drush)
# - custom tools for local dev (e.g. adminer, opcode status page, etc)
#
# Run as root or sudo.
#
# Usage :
# $ . cwt/provision/scripts/debian/8/lamp_setup.sh
#

. cwt/env/load.sh

# Make sure this script only runs once per host.
eval `u_run_once_per_host "$BASH_SOURCE"`

# Host-level dependencies.
. cwt/provision/scripts/debian/8/system/utils.sh
. cwt/provision/scripts/debian/8/system/unattended_upgrades.sh

# Web server.
. cwt/provision/scripts/debian/8/programs/apache/install.sh

# Database.
. cwt/provision/scripts/debian/8/programs/mariadb.sh

# Application dependencies.
. cwt/provision/scripts/debian/8/programs/php/5/install.sh
. cwt/provision/scripts/debian/8/programs/php/5/imagemagik.sh
. cwt/provision/scripts/debian/8/programs/php/5/redis.sh
. cwt/provision/scripts/debian/8/programs/php/5/composer.sh

# Specific application dependencies.
. cwt/provision/scripts/debian/8/programs/drush/8/install.sh

# [optional] Custom tools for local dev.

# PHP Opcode cache status.
# cd /var/www/html
# wget https://raw.githubusercontent.com/rlerdorf/opcache-status/master/opcache.php

# Adminer (DB manager UI).
# mkdir /var/www/html/adminer
# wget https://github.com/vrana/adminer/releases/download/v4.3.1/adminer-4.3.1-mysql-en.php -O /var/www/html/adminer/index.php
