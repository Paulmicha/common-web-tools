#!/usr/bin/env bash

##
# Implements hook -a 'fs_ownership_set' -s 'app instance' -v 'PROVISION_USING HOST_TYPE INSTANCE_TYPE'.
#
# (Re)sets filesystem ownership (except in application source files).
#
# This file is dynamically included when the "hook" is triggered.
# @see u_instance_set_permissions() in cwt/instance/instance.inc.sh
#
# To verify which files can be used (and will be sourced) when this hook is
# triggered :
# $ make hook-debug s:app instance a:fs_ownership_set v:PROVISION_USING HOST_TYPE INSTANCE_TYPE
#

# Sets owner + group to every single file in project root dir. Does not apply to
# files in subfolders.
file_list=''
u_fs_file_list
for f in $file_list; do
  chown "$FS_OWNER:$FS_GROUP" "$f"
  check_chown=$?
  if [ $check_chown -ne 0 ]; then
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO: chown exited with non-zero status ($check_chown)." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    exit 1
  fi
done

# Sets owner + group to every single folder in project root dir. Does not apply
# to subfolders.
dir_list=''
u_fs_dir_list
for d in $dir_list; do
  chown "$FS_OWNER:$FS_GROUP" "$d"
  check_chown=$?
  if [ $check_chown -ne 0 ]; then
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO: chown exited with non-zero status ($check_chown)." >&2
    echo "-> Aborting (2)." >&2
    echo >&2
    exit 2
  fi
done

# Set all CWT source files ownership.
chown "$FS_OWNER:$FS_GROUP" './cwt' -R
check_chown=$?
if [ $check_chown -ne 0 ]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO: chown exited with non-zero status ($check_chown)." >&2
  echo "-> Aborting (3)." >&2
  echo >&2
  exit 3
fi

# Git folder ownership.
if [[ -d './.git' ]]; then
  chown "$FS_OWNER:$FS_GROUP" './.git' -R
  check_chown=$?
  if [ $check_chown -ne 0 ]; then
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO: chown exited with non-zero status ($check_chown)." >&2
    echo "-> Aborting (4)." >&2
    echo >&2
    exit 4
  fi
fi

# Custom scripts ownership.
if [[ -n "$PROJECT_SCRIPTS" ]]; then
  chown "$FS_OWNER:$FS_GROUP" "$PROJECT_SCRIPTS" -R
  check_chown=$?
  if [ $check_chown -ne 0 ]; then
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO: chown exited with non-zero status ($check_chown)." >&2
    echo "-> Aborting (5)." >&2
    echo >&2
    exit 5
  fi
fi
