#!/usr/bin/env bash

##
# Implements hook -a 'fs_ownership_set' -s 'app instance' -v 'PROVISION_USING HOST_TYPE INSTANCE_TYPE'.
#
# (Re)sets the corresponding ownership to any list of paths optionally
# defined in the following globals (env vars) :
# - PROTECTED_FILES : e.g. path to sensitive settings file(s).
# - EXECUTABLE_FILES : e.g. custom app-related scripts.
# - WRITEABLE_DIRS : e.g. path to folders (files, tmp, private) that must be
#     writeable by the application.
# - WRITEABLE_FILES : additional files (outside of WRITEABLE_DIRS) that must be
#     writeable by the application.
#
# This file is dynamically included when the "hook" is triggered.
# @see u_instance_set_ownership() in cwt/instance/instance.inc.sh
#
# To verify which files can be used (and will be sourced) when this hook is
# triggered :
# $ make hook-debug s:app instance a:fs_ownership_set v:PROVISION_USING HOST_TYPE INSTANCE_TYPE
#

if [[ -n "$WRITEABLE_FILES" ]]; then
  for writeable_file in $WRITEABLE_FILES; do
    if [[ ! -f "$writeable_file" ]]; then
      continue
    fi
    echo "Setting writeable file ownership $FS_W_OWNER:$FS_W_GROUP to '$writeable_file'"
    chown "$FS_W_OWNER:$FS_W_GROUP" "$writeable_file"
    check_chown=$?
    if [ $check_chown -ne 0 ]; then
      echo >&2
      echo "Error in $BASH_SOURCE line $LINENO: chown exited with non-zero status ($check_chown)." >&2
      echo "-> Aborting (1)." >&2
      echo >&2
      exit 1
    fi
  done
fi

if [[ -n "$WRITEABLE_DIRS" ]]; then
  for writeable_dir in $WRITEABLE_DIRS; do
    if [[ ! -d "$writeable_dir" ]]; then
      continue
    fi
    echo "Setting writeable dir ownership $FS_W_OWNER:$FS_W_GROUP to '$writeable_dir'"
    chown "$FS_W_OWNER:$FS_W_GROUP" "$writeable_dir" -R
    check_chown=$?
    if [ $check_chown -ne 0 ]; then
      echo >&2
      echo "Error in $BASH_SOURCE line $LINENO: chown exited with non-zero status ($check_chown)." >&2
      echo "-> Aborting (2)." >&2
      echo >&2
      exit 2
    fi
  done
fi
