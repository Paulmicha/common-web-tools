#!/usr/bin/env bash

##
# Implements hook -a 'ensure_dirs_exist' -s 'app'.
#
# Makes sure all git-ignored dirs exist.
#
# This file is dynamically included when the "hook" is triggered.
# @see cwt/instance/instance.inc.sh
#

required_dirs="$DRUPAL_FILES_DIR $DRUPAL_TMP_DIR $DRUPAL_PRIVATE_DIR $DRUPAL_CONFIG_SYNC_DIR"

for required_dir in $required_dirs; do
  echo "Check $required_dir dir exists..."
  if [ -n "$required_dir" ] && [ ! -d "$required_dir" ]; then
    echo "Creating missing dir ${required_dir}."
    mkdir -p "$required_dir"
  fi
done
