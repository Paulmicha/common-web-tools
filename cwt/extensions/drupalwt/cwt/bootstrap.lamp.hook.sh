#!/usr/bin/env bash

##
# Implements hook -s 'cwt' -a 'bootstrap' -v 'PROVISION_USING'.
#
# Declares default bash aliases for current project instance provisionned
# manually (i.e. LAMP stack).
#
# This file is dynamically included when the "hook" is triggered.
# @see cwt/bootstrap.sh
#

alias drush="drush --root=${SERVER_DOCROOT:=/var/www/html}"
alias drupal="${APP_DOCROOT:=app}/vendor/drupal/console/bin/drupal --root=${SERVER_DOCROOT:=/var/www/html}"
