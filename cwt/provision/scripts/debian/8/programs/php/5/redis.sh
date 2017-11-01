#!/bin/bash

##
# Php redis extension setup.
#
# Tested on Debian 8.7 "Jessie"
# @timestamp 2017/07/02 17:49:15
#
# Run as root or sudo.
#

# PHP Redis.
pecl install redis
echo -e "extension=redis.so" > /etc/php5/apache2/conf.d/50-redis.ini
