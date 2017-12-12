#!/usr/bin/env bash

##
# Drush setup.
#
# Tested on Debian 8.7 "Jessie"
# @timestamp 2017/07/02 17:49:15
#
# Run as root or sudo.
#

# Make sure this script only runs once per host.
eval `u_run_once_per_host "$BASH_SOURCE"`

# PHP Drush 8.x (for D6, D7, D8 <= D8.3).
mkdir /usr/local/share/drush
cd /usr/local/share/drush
git clone https://github.com/drush-ops/drush.git -b 8.x .
chmod u+x drush
ln -s /usr/local/share/drush/drush /usr/bin/drush
composer install
