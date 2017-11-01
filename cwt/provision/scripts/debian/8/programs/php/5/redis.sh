#!/bin/bash

##
# Php redis extension setup.
#
# Tested on Debian 8.7 "Jessie"
# @timestamp 2017/07/02 17:49:15
#
# Run as root or sudo.
#

# Make sure this script only runs once per host.
eval `u_run_once_per_host "$BASH_SOURCE"`

# PHP Redis.
pecl install redis
echo -e "extension=redis.so" > /etc/php5/apache2/conf.d/50-redis.ini
