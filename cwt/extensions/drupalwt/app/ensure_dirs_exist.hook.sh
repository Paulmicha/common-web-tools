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

    site_dir_var="dwt_sites_${site_id}_dir"
    site_dir="${!site_dir_var}"

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
            echo "-> Aborting (2)." >&2
            echo >&2
            exit 2
          fi
        fi
      esac
    done
  done
esac
