#!/usr/bin/env bash

##
# Implements hook -a 'fs_perms_set' -s 'app instance' -v 'PROVISION_USING HOST_TYPE INSTANCE_TYPE'.
#
# Applies writeable permissions for multisite setups 'files' dirs.
#
# This file is dynamically included when the "hook" is triggered.
# @see u_instance_set_permissions() in cwt/instance/instance.inc.sh
#
# To verify which files can be used (and will be sourced) when this hook is
# triggered :
# $ make hook-debug s:app instance a:fs_perms_set v:PROVISION_USING HOST_TYPE INSTANCE_TYPE
#

case "$DWT_MULTISITE" in 'true')
  u_dwt_sites
  for site_id in "${dwt_sites_ids[@]}"; do

    site_dir_var="dwt_sites_${site_id}_dir"
    site_dir="${!site_dir_var}"

    # The 'default' dir should be done already (see WRITEABLE_DIRS and
    # PROTECTED_FILES globals).
    # @see cwt/extensions/drupalwt/app/global.vars.sh
    case "$site_dir" in 'default')
      continue
    esac

    files_dir="$DRUPAL_FILES_DIR"
    files_dir=${files_dir/'sites/default'/"sites/$site_dir"}
    if [[ -d "$files_dir" ]]; then
      writeable_dir="$files_dir"
      # HACK : docker-compose projects may have subdirs where this returns many
      # errors we don't care about, so we prevent errors from polluting output.
      # (See docker-compose ownership issues).
      (\
        echo "Setting writeable file permissions $FS_W_FILES to files inside '$writeable_dir'" ; \
        find "$writeable_dir" -type f -exec chmod "$FS_W_FILES" {} + ; \
        echo "Setting writeable dir permissions $FS_W_DIRS to '$writeable_dir'" ; \
        find "$writeable_dir" -type d -exec chmod "$FS_W_DIRS" {} + \
      ) 2> /dev/null
    fi

    drupal_settings="$DRUPAL_SETTINGS_FILE"
    drupal_settings=${drupal_settings/'sites/default'/"sites/$site_dir"}
    if [[ -f "$drupal_settings" ]]; then
      protected_file="$drupal_settings"
      echo "Setting protected file permissions $FS_P_FILES to '$protected_file'"
      chmod "$FS_P_FILES" "$protected_file"
      check_chmod=$?
      if [ $check_chmod -ne 0 ]; then
        echo >&2
        echo "Error in $BASH_SOURCE line $LINENO: chmod exited with non-zero status ($check_chmod)." >&2
        echo "-> Aborting (2)." >&2
        echo >&2
        exit 2
      fi
    fi

    drupal_local_settings="$DRUPAL_SETTINGS_LOCAL_FILE"
    drupal_local_settings=${drupal_local_settings/'sites/default'/"sites/$site_dir"}
    if [[ -f "$drupal_local_settings" ]]; then
      protected_file="$drupal_local_settings"
      echo "Setting protected file permissions $FS_P_FILES to '$protected_file'"
      chmod "$FS_P_FILES" "$protected_file"
      check_chmod=$?
      if [ $check_chmod -ne 0 ]; then
        echo >&2
        echo "Error in $BASH_SOURCE line $LINENO: chmod exited with non-zero status ($check_chmod)." >&2
        echo "-> Aborting (3)." >&2
        echo >&2
        exit 3
      fi
    fi

  done
esac
