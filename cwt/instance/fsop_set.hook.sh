#!/usr/bin/env bash

##
# Implements hook -a 'set_fsop' -s 'app stack'.
#
# (Re)sets common files permissions (except application source files).
#
# This file is dynamically included when the "hook" is triggered.
# @see u_instance_set_permissions() in cwt/instance/instance.inc.sh
#

# Project root files ownership.
chown "$FS_OWNER:$FS_GROUP" ./*

check_chown=$?
if [ $check_chown -ne 0 ]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO: chown exited with non-zero status ($check_chown)." >&2
  echo "-> Aborting (1)." >&2
  echo >&2
  exit 1
fi

# Project root non-writeable files permissions.
find . -maxdepth 1 -type f -exec chmod $FS_NW_FILES {} +

# check_chmod=$?
# if [ $check_chmod -ne 0 ]; then
#   echo >&2
#   echo "Error in $BASH_SOURCE line $LINENO: chmod exited with non-zero status ($check_chmod)." >&2
#   echo "-> Aborting (2)." >&2
#   echo >&2
#   exit 2
# fi

# Project root folders permissions.
find . -maxdepth 1 -type d -exec chmod $FS_NW_DIRS {} +

# CWT source files ownership.
chown "$FS_OWNER:$FS_GROUP" ./cwt -R

check_chown=$?
if [ $check_chown -ne 0 ]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO: chown exited with non-zero status ($check_chown)." >&2
  echo "-> Aborting (3)." >&2
  echo >&2
  exit 3
fi

# CWT non-writeable files permissions.
find ./cwt -type f -exec chmod $FS_NW_FILES {} +

# CWT non-writeable folders permissions.
find ./cwt -type d -exec chmod $FS_NW_DIRS {} +


# Git folders permissions.
if [[ -d ./.git ]]; then
  chown "$FS_OWNER:$FS_GROUP" ./.git -R
  find ./.git -type f -exec chmod $FS_NW_FILES {} +
fi


# If custom scripts dir is defined, also (re)set its ownership and permissions.
if [[ -n "$PROJECT_SCRIPTS" ]]; then

  # Custom scripts ownership.
  chown "$FS_OWNER:$FS_GROUP" "$PROJECT_SCRIPTS" -R

  check_chown=$?
  if [ $check_chown -ne 0 ]; then
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO: chown exited with non-zero status ($check_chown)." >&2
    echo "-> Aborting (4)." >&2
    echo >&2
    exit 4
  fi

  # Custom scripts subfolders permission.
  find "$PROJECT_SCRIPTS" -type d -exec chmod $FS_NW_DIRS {} +

  # Custom scripts executable permission.
  find "$PROJECT_SCRIPTS" -type f -exec chmod $FS_E_FILES {} +

fi
