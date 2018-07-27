#!/usr/bin/env bash

##
# Implements hook -a 'set_fsop' -s 'app stack'.
#
# This file is dynamically included when the "hook" is triggered.
# @see cwt/instance/instance.inc.sh
#

CHMOD_W_FILES='0775'
CHMOD_W_DIRS='1771'
CHMOD_NW_FILES='0755'
CHMOD_NW_DIRS='0755'

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
