#!/usr/bin/env bash

##
# Implements hook -a 'fs_perms_set' -s 'app instance' -v 'STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE'.
#
# (Re)sets project root filesystem permissions (except application sources).
#
# This file is dynamically included when the "hook" is triggered.
# @see u_instance_set_permissions() in cwt/instance/instance.inc.sh
#
# To verify which files can be used (and will be sourced) when this hook is
# triggered :
# $ make hook-debug s:app instance a:fs_perms_set v:STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE
#

# Sets 'normal' file permissions (644 by default) to every single file in
# project root dir. Does not apply to files in subfolders.
file_list=''
u_fs_file_list
for f in $file_list; do
  chmod "$FS_NW_FILES" "$f"
  check_chmod=$?
  if [ $check_chmod -ne 0 ]; then
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO: chmod exited with non-zero status ($check_chmod)." >&2
    echo "-> Aborting (2)." >&2
    echo >&2
    exit 2
  fi
done

# Sets 'normal' dir permissions (755 by default) to every single folder in
# project root dir. Does not apply to subfolders.
dir_list=''
u_fs_dir_list
for d in $dir_list; do
  chmod "$FS_NW_DIRS" "$d"
  # Some bind mounts for app dir may need different ownership -> do not enforce.
  # check_chmod=$?
  # if [ $check_chmod -ne 0 ]; then
  #   echo >&2
  #   echo "Error in $BASH_SOURCE line $LINENO: chmod exited with non-zero status ($check_chmod)." >&2
  #   echo "-> Aborting (3)." >&2
  #   echo >&2
  #   exit 3
  # fi
done

# Sets 'normal' file permissions (644 by default) to CWT files. Applies to files
# in subfolders.
find './cwt' -type f -exec chmod "$FS_NW_FILES" {} +

# Sets 'normal' dir permissions (755 by default) to CWT folders. Applies to
# subfolders.
find './cwt' -type d -exec chmod "$FS_NW_DIRS" {} +

# CWT "actions" - and the ones of its active extensions - need to be executable.
u_cwt_get_actions
for f in "${cwt_action_scripts[@]}"; do
  chmod "$FS_E_FILES" "$f"
  check_chmod=$?
  if [ $check_chmod -ne 0 ]; then
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO: chmod exited with non-zero status ($check_chmod)." >&2
    echo "-> Aborting (4)." >&2
    echo >&2
    exit 4
  fi
done

# Test files need to be executable.
file_list=''
u_fs_file_list './' '*.test.sh' 32
for f in $file_list; do
  chmod "$FS_E_FILES" "./$f"
  check_chmod=$?
  if [ $check_chmod -ne 0 ]; then
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO: chmod exited with non-zero status ($check_chmod)." >&2
    echo "-> Aborting (5)." >&2
    echo >&2
    exit 5
  fi
done

# CWT make shortcut scripts as well.
file_list=''
u_fs_file_list './cwt' '*.make.sh' 32
file_list+=' escape.sh'
for f in $file_list; do
  chmod "$FS_E_FILES" "./cwt/$f"
  check_chmod=$?
  if [ $check_chmod -ne 0 ]; then
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO: chmod exited with non-zero status ($check_chmod)." >&2
    echo "-> Aborting (6)." >&2
    echo >&2
    exit 6
  fi
done

# Same for '.git' folders and files, except for git hooks which need executable
# file permissions.
if [[ -d './.git' ]]; then
  find './.git' -type f -exec chmod "$FS_NW_FILES" {} +
  find './.git' -type d -exec chmod "$FS_NW_DIRS" {} +
  find './.git/hooks' -type f -exec chmod "$FS_E_FILES" {} +
fi

# Same for custom scripts dir if it exists.
if [[ -d './scripts' ]]; then
  chmod "$FS_NW_DIRS" './scripts'
  check_chmod=$?
  if [ $check_chmod -ne 0 ]; then
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO: chmod exited with non-zero status ($check_chmod)." >&2
    echo "-> Aborting (7)." >&2
    echo >&2
    exit 7
  fi
  find './scripts' -type d -exec chmod "$FS_NW_DIRS" {} +
  find './scripts' -type f -exec chmod "$FS_E_FILES" {} +
fi

# TODO should CWT enforce this ? Loop through env vars named like :
#   - PROTECTED_FILES
#   - EXECUTABLE_FILES
#   - WRITEABLE_DIRS
#   - WRITEABLE_FILES
