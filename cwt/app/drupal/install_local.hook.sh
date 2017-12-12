#!/usr/bin/env bash

##
# Implements u_hook_app 'install' 'local'.
#
# This file is dynamically included when the "hook" is triggered.
#

# Ensures required (and/or gitignored) dirs exist.
required_dirs="$DRUPAL_FILES_DIR $DRUPAL_TMP_DIR $DRUPAL_PRIVATE_DIR"
for required_dir in $required_dirs; do

  echo "Check $required_dir dir exists..."

  if [[ (-n "$required_dir") && (! -d "$required_dir") ]]; then
    echo "Creating missing dir ${required_dir}."
    mkdir -p "$required_dir"
    # TODO error handling.
  fi
done
