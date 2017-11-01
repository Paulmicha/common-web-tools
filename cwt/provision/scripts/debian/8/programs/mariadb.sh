#!/bin/bash

##
# MariaDB setup.
#
# Tested on Debian 8.7 "Jessie"
# @timestamp 2017/07/02 17:49:15
#
# Generates MariaDB root password & write it in ~/lamp/.mariadb.env
# TODO replace hardcoded storage for root password with e.g.:
# @see cwt/env/registry.sh
#
# Run as root or sudo.
#

# MariaDB.
# Generates MariaDB root password & write it in ~/lamp/.mariadb.env
DB_ROOT_PASSWORD=`< /dev/urandom tr -dc A-Za-z0-9 | head -c14; echo`
echo "DB_ROOT_PASSWORD=$DB_ROOT_PASSWORD" > ~/lamp/.mariadb.env
DEBIAN_FRONTEND='noninteractive' apt install mariadb-client mariadb-server -y
echo "SET PASSWORD FOR 'root'@'localhost' = PASSWORD('${DB_ROOT_PASSWORD}')" | mysql --user=root
