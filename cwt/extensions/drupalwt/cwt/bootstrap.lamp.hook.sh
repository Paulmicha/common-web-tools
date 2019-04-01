#!/usr/bin/env bash

##
# Implements hook -s 'cwt' -a 'bootstrap' -v 'PROVISION_USING'.
#
# Declares default bash aliases for current project instance provisionned
# manually (LAMP stack).
#
# This file is dynamically included when the "hook" is triggered.
# @see cwt/bootstrap.sh
#

# Even for instances not using docker-compose (where drush must already be
# installed), make an alias for execution from dev stack dir ($PROJECT_DOCROOT).
alias drush="drush --root=${APP_DOCROOT:=/var/www/html}"
