#!/bin/bash

##
# Implements u_hook_app_call 'apply' 'ownership_and_perms'.
#
# This file is dynamically included when the "hook" is triggered.
#
# TODO this assumes ownership_and_perms settings for any drupal app provisioned
# with docker-compose, and should be overridden if necessary.
# @see u_autoload_override()
# @see u_hook_call()
#

# User 82 is www-data in Docker images like wodby/drupal-php.
if [[ -n "$APP_DOCROOT" ]]; then
  chown 82:82 "$APP_DOCROOT" -R
fi
