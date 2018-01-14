#!/usr/bin/env bash

##
# Implements u_hook_app 'apply' 'ownership_and_perms'.
#
# This file is dynamically included when the "hook" is triggered.
#
# TODO this assumes ownership_and_perms settings for any drupal app provisioned
# with docker-compose, and should be overridden if necessary.
# @see u_autoload_override()
# @see u_hook()
#

# TODO [wip] handle differences like php-fpm / apache.
CHMOD_W_FILES='0770'
CHMOD_W_DIRS='1771'
CHMOD_NW_FILES='0750'
CHMOD_NW_DIRS='0750'

# User 82 is www-data in Docker images like wodby/drupal-php.
if [[ -n "$APP_DOCROOT" ]]; then

  # Common ownership.
  chown 82:82 "$APP_DOCROOT" -R

  # Non-writeable files.
  find "$APP_DOCROOT" -type f -exec chmod $CHMOD_NW_FILES {} +

  # Non-writeable dirs.
  find "$APP_DOCROOT" -type d -exec chmod $CHMOD_NW_DIRS {} +
fi

if [[ -n "$WRITEABLE_DIRS" ]]; then
  for writeable_dir in $WRITEABLE_DIRS; do

    # Common ownership in writeable dirs.
    chown 82:82 "$writeable_dir" -R

    # Writeable files.
    find "$writeable_dir" -type f -exec chmod $CHMOD_W_FILES {} +

    # Writeable dirs.
    find "$writeable_dir" -type d -exec chmod $CHMOD_W_DIRS {} +
  done
fi

if [[ -n "$WRITEABLE_FILES" ]]; then
  for writeable_file in $WRITEABLE_FILES; do

    # Common ownership in writeable files.
    chown 82:82 "$writeable_file"

    chmod $CHMOD_W_FILES "$writeable_file"
  done
fi
