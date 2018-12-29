#!/usr/bin/env bash

##
# Implements hook -a 'fs_perms_set' -s 'app instance' -v 'PROVISION_USING HOST_TYPE INSTANCE_TYPE'.
#
# (Re)sets the corresponding permissions to any list of paths optionally
# defined in the following globals (env vars) :
# - PROTECTED_FILES : e.g. path to sensitive settings file(s).
# - EXECUTABLE_FILES : e.g. custom app-related scripts.
# - WRITEABLE_DIRS : e.g. path to folders (files, tmp, private) that must be
#     writeable by the application.
# - WRITEABLE_FILES : additional files (outside of WRITEABLE_DIRS) that must be
#     writeable by the application.
#
# This file is dynamically included when the "hook" is triggered.
# @see u_instance_set_permissions() in cwt/instance/instance.inc.sh
#
# To verify which files can be used (and will be sourced) when this hook is
# triggered :
# $ make hook-debug s:app instance a:fs_perms_set
#

if [[ -n "$WRITEABLE_FILES" ]]; then
  for writeable_file in $WRITEABLE_FILES; do
    chmod "$FS_W_FILES" "$writeable_file"
    check_chmod=$?
    if [ $check_chmod -ne 0 ]; then
      echo >&2
      echo "Error in $BASH_SOURCE line $LINENO: chmod exited with non-zero status ($check_chmod)." >&2
      echo "-> Aborting (1)." >&2
      echo >&2
      exit 1
    fi
  done
fi

if [[ -n "$WRITEABLE_DIRS" ]]; then
  for writeable_dir in $WRITEABLE_DIRS; do
    find "$writeable_dir" -type f -exec chmod "$FS_W_FILES" {} +
    find "$writeable_dir" -type d -exec chmod "$FS_W_DIRS" {} +
  done
fi

if [[ -n "$PROTECTED_FILES" ]]; then
  for protected_file in $PROTECTED_FILES; do
    chmod "$FS_P_FILES" "$protected_file"
    check_chmod=$?
    if [ $check_chmod -ne 0 ]; then
      echo >&2
      echo "Error in $BASH_SOURCE line $LINENO: chmod exited with non-zero status ($check_chmod)." >&2
      echo "-> Aborting (2)." >&2
      echo >&2
      exit 2
    fi
  done
fi

if [[ -n "$EXECUTABLE_FILES" ]]; then
  for executable_file in $EXECUTABLE_FILES; do
    chmod "$FS_E_FILES" "$executable_file"
    check_chmod=$?
    if [ $check_chmod -ne 0 ]; then
      echo >&2
      echo "Error in $BASH_SOURCE line $LINENO: chmod exited with non-zero status ($check_chmod)." >&2
      echo "-> Aborting (3)." >&2
      echo >&2
      exit 3
    fi
  done
fi
