#!/bin/bash

##
# Php setup.
#
# Tested on Debian 8.7 "Jessie"
# @timestamp 2017/07/02 17:49:15
#
# TODO configuration management (hardcoded) - validate assumption : we could
# just leave a base then override as needed. Evol: using dedicated scripts (e.g.
# wrapping sed calls).
#
# Run as root or sudo.
#

apt install php5 php5-dev php5-cli php5-common php5-mysql php5-curl php-pear php5-gd php5-mcrypt -y
apt install php5-intl -y

apt install sqlite3 -y
apt install php5-sqlite -y

# PHP Upload Progress.
pecl install uploadprogress
echo -e "extension=uploadprogress.so" > /etc/php5/apache2/conf.d/50-uploadprogress.ini

# PHP UTF-8 for mbstring.
echo -e "; Set mbstring defaults to UTF-8
mbstring.language=UTF-8
mbstring.internal_encoding=UTF-8
mbstring.detect_order=auto" > /etc/php5/apache2/conf.d/20-mbstring.ini

# PHP main configuration (NB: creates a backup on the 1st call).
sed -e 's,memory_limit = 128M,memory_limit = 512M,g' -i.bak /etc/php5/apache2/php.ini
sed -e 's,max_execution_time = 30,max_execution_time = 180,g' -i /etc/php5/apache2/php.ini
sed -e 's,upload_max_filesize = 2M,upload_max_filesize = 50M,g' -i /etc/php5/apache2/php.ini
sed -e 's,max_input_time = 60,max_input_time = 120,g' -i /etc/php5/apache2/php.ini
sed -e 's,post_max_size = 8M,post_max_size = 60M,g' -i /etc/php5/apache2/php.ini
sed -e 's,;date.timezone =,date.timezone = '$(command cat /etc/timezone)',g' -i /etc/php5/apache2/php.ini

# PHP Opcode Cache.
echo "opcache.memory_consumption=384" >> /etc/php5/mods-available/opcache.ini
