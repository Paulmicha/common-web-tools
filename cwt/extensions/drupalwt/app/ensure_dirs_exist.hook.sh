#!/usr/bin/env bash

##
# Implements hook -a 'ensure_dirs_exist' -s 'app'.
#
# Makes sure all git-ignored dirs exist.
#
# This file is dynamically included when the "hook" is triggered.
# @see cwt/instance/instance.inc.sh
#

required_dirs="$DRUPAL_FILES_DIR $DRUPAL_TMP_DIR $DRUPAL_PRIVATE_DIR"

if [[ $DRUPAL_VERSION -ne 7 ]]; then
  required_dirs+=" $DRUPAL_CONFIG_SYNC_DIR"
fi

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

    # Optionally git-ignored config sync dirs need to be dealt with.
    v="dwt_sites_${site_id}_config_sync_dir"
    config_sync_dir="${!v}"
    if [[ -n "$config_sync_dir" ]] && [[ ! -d "$SERVER_DOCROOT/$config_sync_dir" ]]; then
      echo "Creating missing dir '$SERVER_DOCROOT/$config_sync_dir'"
      mkdir -p "$SERVER_DOCROOT/$config_sync_dir"
      if [[ $? -ne 0 ]]; then
        echo >&2
        echo "Error in $BASH_SOURCE line $LINENO: unable to create the required dir '$SERVER_DOCROOT/$config_sync_dir'." >&2
        echo "-> Aborting (2)." >&2
        echo >&2
        exit 2
      fi
    fi

    # Process required dirs for all local sites.
    v="dwt_sites_${site_id}_dir"
    site_dir="${!v}"

    # The 'default' dir should be done already.
    # @see cwt/extensions/drupalwt/app/global.vars.sh
    case "$site_dir" in 'default')
      continue
    esac

    for required_dir in $required_dirs; do
      case "$required_dir" in *'sites/default/'*)
        required_dir=${required_dir/'sites/default/'/"sites/$site_dir/"}
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
      esac
    done
  done
esac
