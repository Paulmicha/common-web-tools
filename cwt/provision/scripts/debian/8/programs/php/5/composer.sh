#!/bin/bash

##
# Composer setup.
#
# Tested on Debian 8.7 "Jessie"
# @timestamp 2017/07/02 17:49:15
#
# Run as root or sudo.
#

# Make sure this script only runs once per host.
eval `u_run_once_per_host "$BASH_SOURCE"`

cd /usr/local/bin
curl -s http://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer
composer global require hirak/prestissimo
