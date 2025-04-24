#!/usr/bin/env bash

##
# Implements hook -s 'app instance' -a 'fs_perms_get' -v 'STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE'
#
# Provide the user who must be set as owner of dirs and files writeable by php.
# To apply, run :
#   sudo cwt/instance/fix_perms.sh
#   # Or :
#   sudo make fix-perms
#
# Here are the variable names that can be set here and their default value :
# FS_NW_FILES : [optional] permissions to apply to Non-Writeable files.
#   Defaults to 0644.
# FS_NW_DIRS : [optional] permissions to apply to Non-Writeable folders.
#   Defaults to 0755.
# FS_P_FILES : [optional] permissions to apply to Protected files.
#   Defaults to 0444.
# FS_E_FILES : [optional] permissions to apply to Exectuable files.
#   Defaults to 0755.
# FS_W_FILES : [optional] permissions to apply to Writeable files.
#   Defaults to 0774.
# FS_W_DIRS: [optional] permissions to apply to Writeable folders.
#   Defaults to 1771.
#
# This file is dynamically included when the "hook" is triggered.
# @see u_instance_get_perms() in cwt/instance/instance.inc.sh
#
# To verify which files can be used (and will be sourced) when this hook is
# triggered :
# $ make hook-debug s:app instance a:fs_perms_get v:STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE
#

# TODO [hack] Workaround docker-related ownership issue (make writeable dirs &
# files world-writeable).
FS_W_FILES='777'
FS_W_DIRS='777'
