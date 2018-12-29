#!/usr/bin/env bash

##
# Implements hook -a 'fs_ownership_pre_set' -s 'app instance' -v 'PROVISION_USING HOST_TYPE INSTANCE_TYPE'.
#
# (Re)sets filesystem permissions in application source files. This hook is
# triggered before the 'normal' hook is triggered to ensure specific lists
# of files which may be contained in app sources get their permissions applied
# correctly afterwards.
#
# @see cwt/app/fs_ownership_set.hook.sh
#
# This file is dynamically included when the "hook" is triggered.
# @see u_instance_set_permissions() in cwt/instance/instance.inc.sh
#
# To verify which files can be used (and will be sourced) when this hook is
# triggered :
# $ make hook-debug s:app instance a:fs_ownership_pre_set
#

# Handle projects using different Git repos for dev-stack and app.
app_files_path="$APP_DOCROOT"
if [[ -n "$APP_GIT_WORK_TREE" ]] && [[ -d "$APP_GIT_WORK_TREE" ]]; then
  app_files_path="$APP_GIT_WORK_TREE"
fi

if [[ -n "$app_files_path" ]]; then
  # Sets 'normal' file ownership to files and folders in application dir.
  # Applies subfolders.
  chown "$FS_OWNER:$FS_GROUP" "$app_files_path" -R
  check_chown=$?
  if [ $check_chown -ne 0 ]; then
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO: chown exited with non-zero status ($check_chown)." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    exit 1
  fi
fi
