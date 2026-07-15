#!/usr/bin/env bash

##
# Implements hook -a 'fs_ownership_set' -s 'app instance' -v 'STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE'.
#
# (Re)sets ownership for CWT-managed paths only.
#
# By default, only touches ./cwt, ./scripts/cwt, and ./.git. Application
# sources and project root entries are handled by extension hooks when needed.
#
# This file is dynamically included when the "hook" is triggered.
# @see u_instance_set_permissions() in cwt/instance/instance.inc.sh
#
# To verify which files can be used (and will be sourced) when this hook is
# triggered :
# $ make hook-debug s:app instance a:fs_ownership_set v:STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE
#

for base_dir in './data' './cwt' './scripts/cwt' './.git'; do
  if [[ ! -d "$base_dir" ]]; then
    continue
  fi

  chown "$FS_OWNER:$FS_GROUP" "$base_dir" -R
  check_chown=$?

  if [ $check_chown -ne 0 ]; then
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO: chown exited with non-zero status ($check_chown)." >&2
    echo "-> Aborting." >&2
    echo >&2
    exit 1
  fi
done
