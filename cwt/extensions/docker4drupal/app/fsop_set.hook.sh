#!/usr/bin/env bash

##
# Implements hook -a 'set_fsop' -s 'app stack'.
#
# This file is dynamically included when the "hook" is triggered.
# @see u_instance_set_permissions() in cwt/instance/instance.inc.sh
#

# Handle projects using different Git repos for dev-stack and app.
app_files_path="$APP_DOCROOT"
if [[ -n "$APP_GIT_WORK_TREE" ]] && [[ -d "$APP_GIT_WORK_TREE" ]]; then
  app_files_path="$APP_GIT_WORK_TREE"
fi

if [[ -n "$app_files_path" ]]; then
  # Common ownership.
  chown "$FS_OWNER:$FS_GROUP" "$app_files_path" -R

  check_chown=$?
  if [ $check_chown -ne 0 ]; then
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO: chown exited with non-zero status ($check_chown)." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    exit 1
  fi

  # Non-writeable files.
  find "$app_files_path" -type f -exec chmod $FS_NW_FILES {} +

  # Non-writeable dirs.
  find "$app_files_path" -type d -exec chmod $FS_NW_DIRS {} +
fi


if [[ -n "$WRITEABLE_DIRS" ]]; then
  for writeable_dir in $WRITEABLE_DIRS; do

    # Common ownership in writeable dirs.
    chown "$FS_W_OWNER:$FS_W_GROUP" "$writeable_dir" -R

    check_chown=$?
    if [ $check_chown -ne 0 ]; then
      echo >&2
      echo "Error in $BASH_SOURCE line $LINENO: chown exited with non-zero status ($check_chown)." >&2
      echo "-> Aborting (2)." >&2
      echo >&2
      exit 2
    fi

    # Writeable files.
    find "$writeable_dir" -type f -exec chmod $FS_W_FILES {} +

    # Writeable dirs.
    find "$writeable_dir" -type d -exec chmod $FS_W_DIRS {} +
  done
fi


if [[ -n "$WRITEABLE_FILES" ]]; then
  for writeable_file in $WRITEABLE_FILES; do

    # Common ownership in writeable files.
    chown "$FS_W_OWNER:$FS_W_GROUP" "$writeable_file"

    check_chown=$?
    if [ $check_chown -ne 0 ]; then
      echo >&2
      echo "Error in $BASH_SOURCE line $LINENO: chown exited with non-zero status ($check_chown)." >&2
      echo "-> Aborting (3)." >&2
      echo >&2
      exit 3
    fi

    chmod "$FS_W_FILES" "$writeable_file"

    check_chmod=$?
    if [ $check_chmod -ne 0 ]; then
      echo >&2
      echo "Error in $BASH_SOURCE line $LINENO: chmod exited with non-zero status ($check_chmod)." >&2
      echo "-> Aborting (4)." >&2
      echo >&2
      exit 4
    fi
  done
fi


if [[ -n "$PROTECTED_FILES" ]]; then
  for protected_file in $PROTECTED_FILES; do

    chmod "$FS_P_FILES" "$protected_file"

    check_chmod=$?
    if [ $check_chmod -ne 0 ]; then
      echo >&2
      echo "Error in $BASH_SOURCE line $LINENO: chmod exited with non-zero status ($check_chmod)." >&2
      echo "-> Aborting (5)." >&2
      echo >&2
      exit 5
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
      echo "-> Aborting (6)." >&2
      echo >&2
      exit 6
    fi
  done
fi
