#!/usr/bin/env bash

##
# Implements hook -s 'cwt' -a 'alias' -v 'STACK_VERSION PROVISION_USING'.
#
# Declares default bash aliases for current project instance provisionned
# manually (i.e. LAMP stack).
#
# This file is dynamically included when the "hook" is triggered.
# @see cwt/bootstrap.sh
#

alias drupal="${APP_DOCROOT:=app}/vendor/drupal/console/bin/drupal --root=${SERVER_DOCROOT:=/var/www/html}"
