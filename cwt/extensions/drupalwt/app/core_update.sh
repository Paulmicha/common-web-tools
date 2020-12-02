#!/usr/bin/env bash

##
# Updates Drupal core (if you are using drupal/core-recommended).
#
# Also runs DB update & clears caches.
#
# See https://www.drupal.org/docs/updating-drupal/updating-drupal-core-via-composer
#
# @example
#   make app-core-update
#   # Or :
#   cwt/extensions/drupalwt/app/core_update.sh
#

. cwt/bootstrap.sh

composer update drupal/core 'drupal/core-*' --with-all-dependencies
drush updatedb -y
drush cr
