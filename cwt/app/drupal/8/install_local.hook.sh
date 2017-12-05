#!/bin/bash

##
# Implements u_hook_app 'install' 'local'.
#
# This file is dynamically included when the "hook" is triggered.
#

# Ensures required (and/or gitignored) dirs exist.
echo "Check $DRUPAL_CONFIG_SYNC_DIR dir exists..."
if [[ (-n "$DRUPAL_CONFIG_SYNC_DIR") && (! -d "$DRUPAL_CONFIG_SYNC_DIR") ]]; then
  echo "Creating missing dir ${DRUPAL_CONFIG_SYNC_DIR}."
  mkdir -p "$DRUPAL_CONFIG_SYNC_DIR"
  # TODO error handling.
fi
