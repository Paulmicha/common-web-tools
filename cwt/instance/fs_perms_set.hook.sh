#!/usr/bin/env bash

##
# Implements hook -a 'fs_perms_set' -s 'app instance' -v 'STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE'.
#
# (Re)sets CWT-managed filesystem permissions.
#
# By default, only touches ./data, ./cwt, ./scripts/cwt, and ./.git. Application
# sources and project root entries are handled by extension hooks (e.g.
# fs_perms_pre_set) when needed.
#
# This file is dynamically included when the "hook" is triggered.
# @see u_instance_set_permissions() in cwt/instance/instance.inc.sh
#
# To verify which files can be used (and will be sourced) when this hook is
# triggered :
# $ make hook-debug s:app instance a:fs_perms_set v:STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE
#

# Whitelisted root files default permissions.
default_files=()
default_files+=('./.env')
default_files+=('./.gitconfig')
default_files+=('./.gitignore')
default_files+=('./env.yml')
default_files+=('./Makefile')

for f in "${default_files[@]}"; do
  if [[ ! -f "$f" ]]; then
    continue
  fi

  chmod "$FS_NW_FILES" "$f"
  check_chmod=$?

  if [ $check_chmod -ne 0 ]; then
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO: 'chmod $FS_NW_FILES $f' exited with non-zero status ($check_chmod)." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    exit 1
  fi
done

# CWT "core" files and folders default permissions.
if [[ -d './cwt' ]]; then
  find './cwt' -type f -exec chmod "$FS_NW_FILES" {} +
  find './cwt' -type d -exec chmod "$FS_NW_DIRS" {} +
fi

# CWT project-specific files and folders default permissions.
if [[ -d './scripts' ]]; then
  chmod "$FS_NW_DIRS" './scripts'
  check_chmod=$?

  if [ $check_chmod -ne 0 ]; then
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO: chmod exited with non-zero status ($check_chmod)." >&2
    echo "-> Aborting (2)." >&2
    echo >&2
    exit 2
  fi
fi

if [[ -d './scripts/cwt' ]]; then
  chmod "$FS_NW_DIRS" './scripts/cwt'
  check_chmod=$?

  if [ $check_chmod -ne 0 ]; then
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO: chmod exited with non-zero status ($check_chmod)." >&2
    echo "-> Aborting (3)." >&2
    echo >&2
    exit 3
  fi

  find './scripts/cwt' -type d -exec chmod "$FS_NW_DIRS" {} +
  find './scripts/cwt' -type f -exec chmod "$FS_E_FILES" {} +
fi

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

# Apply the ./data folder default permissions.

# Test files (*.test.sh in ./cwt and ./scripts/cwt) need to be executable.
# CWT make shortcut scripts as well.
for scope in './cwt' './scripts/cwt'; do
  if [[ ! -d "$scope" ]]; then
    continue
  fi

  # Test files (*.test.sh).
  file_list=''
  u_fs_file_list "$scope" '*.test.sh' 32

  for f in $file_list; do
    chmod "$FS_E_FILES" "$scope/$f"
    check_chmod=$?

    if [ $check_chmod -ne 0 ]; then
      echo >&2
      echo "Error in $BASH_SOURCE line $LINENO: chmod exited with non-zero status ($check_chmod)." >&2
      echo "-> Aborting (5)." >&2
      echo >&2
      exit 5
    fi
  done

  # CWT make shortcut scripts (*.make.sh), wrappers (*.wrap.sh), and helpers.
  # escape.sh / list_entry_points.sh live only under ./cwt.
  file_list=''
  u_fs_file_list "$scope" '*.make.sh' 32

  wrap_list=''
  u_fs_file_list "$scope" '*.wrap.sh' 32

  file_list+=" $wrap_list"

  if [[ "$scope" == './cwt' ]]; then
    file_list+=' escape.sh make/list_entry_points.sh'
  fi

  for f in $file_list; do
    if [[ ! -f "$scope/$f" ]]; then
      continue
    fi

    chmod "$FS_E_FILES" "$scope/$f"
    check_chmod=$?

    if [ $check_chmod -ne 0 ]; then
      echo >&2
      echo "Error in $BASH_SOURCE line $LINENO: chmod exited with non-zero status ($check_chmod)." >&2
      echo "-> Aborting (6)." >&2
      echo >&2
      exit 6
    fi
  done
done

# Same for '.git' folders and files, except for git hooks which need executable
# file permissions.
if [[ -d './.git' ]]; then
  find './.git' -type f -exec chmod "$FS_NW_FILES" {} +
  find './.git' -type d -exec chmod "$FS_NW_DIRS" {} +

  if [[ -d './.git/hooks' ]]; then
    find './.git/hooks' -type f -exec chmod "$FS_E_FILES" {} +
  fi
fi

# Writeable dirs, if declared, must have their permissions enforced by default.
if [[ -n "$WRITEABLE_DIRS" ]]; then
  for d in $WRITEABLE_DIRS; do
    if [[ ! -d "$d" ]]; then
      continue
    fi

    chmod "$FS_W_DIRS" "$d"
    check_chmod=$?

    if [ $check_chmod -ne 0 ]; then
      echo >&2
      echo "Error in $BASH_SOURCE line $LINENO: chmod exited with non-zero status ($check_chmod)." >&2
      echo "-> Aborting (7)." >&2
      echo >&2
      exit 7
    fi
  done
fi


# Writeable files, if declared, must have their permissions enforced by default.
if [[ -n "$WRITEABLE_FILES" ]]; then
  for f in $WRITEABLE_FILES; do
    if [[ ! -f "$f" ]]; then
      continue
    fi

    chmod "$FS_E_FILES" "$f"
    check_chmod=$?

    if [ $check_chmod -ne 0 ]; then
      echo >&2
      echo "Error in $BASH_SOURCE line $LINENO: chmod exited with non-zero status ($check_chmod)." >&2
      echo "-> Aborting (8)." >&2
      echo >&2
      exit 8
    fi
  done
fi

# Executable files, if declared, must have their permissions enforced by default.
if [[ -n "$EXECUTABLE_FILES" ]]; then
  for f in $EXECUTABLE_FILES; do
    if [[ ! -f "$f" ]]; then
      continue
    fi

    chmod "$FS_E_FILES" "$f"
    check_chmod=$?

    if [ $check_chmod -ne 0 ]; then
      echo >&2
      echo "Error in $BASH_SOURCE line $LINENO: chmod exited with non-zero status ($check_chmod)." >&2
      echo "-> Aborting (9)." >&2
      echo >&2
      exit 9
    fi
  done
fi

# Protected files, if declared, must have their permissions enforced by default.
if [[ -n "$PROTECTED_FILES" ]]; then
  for f in $PROTECTED_FILES; do
    if [[ ! -f "$f" ]]; then
      continue
    fi

    chmod "$FS_P_FILES" "$f"
    check_chmod=$?

    if [ $check_chmod -ne 0 ]; then
      echo >&2
      echo "Error in $BASH_SOURCE line $LINENO: chmod exited with non-zero status ($check_chmod)." >&2
      echo "-> Aborting (10)." >&2
      echo >&2
      exit 10
    fi
  done
fi
