#!/usr/bin/env bash

##
# Implements hook -a 'ensure_dirs_exist' -s 'app'.
#
# Makes sure all git-ignored dirs exist :
# - DRUPAL_FILES_DIR
# - DRUPAL_TMP_DIR
# - DRUPAL_TRANSLATION_DIR # Update : this does not appear to be supported in settings file declaration -> commented out for now
# - DRUPAL_CONFIG_SYNC_DIR
# - DRUPAL_PRIVATE_DIR
#
# This file is dynamically included when the "hook" is triggered.
# @see cwt/instance/instance.inc.sh
#

# required_dirs="$DRUPAL_FILES_DIR $DRUPAL_TMP_DIR $DRUPAL_TRANSLATION_DIR $DRUPAL_CONFIG_SYNC_DIR $DRUPAL_PRIVATE_DIR"
required_dirs="$DRUPAL_FILES_DIR $DRUPAL_TMP_DIR $DRUPAL_CONFIG_SYNC_DIR $DRUPAL_PRIVATE_DIR"

for required_dir in $required_dirs; do
  if [[ -n "$required_dir" ]] && [[ ! -d "$required_dir" ]]; then

    echo "Creating missing dir ${required_dir}"
    mkdir -p "$required_dir"

    if [[ $? -ne 0 ]]; then
      echo >&2
      echo "Error in $BASH_SOURCE line $LINENO: unable to create the required dir '$required_dir'." >&2
      echo "-> Aborting (1)." >&2
      echo >&2
      exit 1
    fi
  fi
done

# Multisite support.
case "$DWT_MULTISITE" in 'true')
  u_dwt_sites
  for site_id in "${dwt_sites_ids[@]}"; do
    u_str_sanitize_var_name "$site_id" 'site_id'

    # The 'default' dir should be done already.
    # @see cwt/extensions/drupalwt/app/global.vars.sh
    case "$site_dir" in 'default')
      continue
    esac

    dwt_sites_writeable_paths=()
    u_dwt_get_sites_writeable_paths "$site_id"
    for required_dir in "${dwt_sites_writeable_paths[@]}"; do
      if [[ ! -d "$required_dir" ]]; then
        echo "Creating missing dir ${required_dir}"
        mkdir -p "$required_dir"
        if [[ $? -ne 0 ]]; then
          echo >&2
          echo "Error in $BASH_SOURCE line $LINENO: unable to create the required dir '$required_dir'." >&2
          echo "-> Aborting (3)." >&2
          echo >&2
          exit 3
        fi
      fi
    done
  done
esac
