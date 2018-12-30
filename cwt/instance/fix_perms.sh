#!/usr/bin/env bash

##
# (Re)sets filesystem permissions.
#
# @see u_instance_set_permissions() in cwt/instance/instance.inc.sh
# @see cwt/instance/fs_perms_set.hook.sh
#
# @example
#   make fix_perms
#   # Or :
#   cwt/instance/fix_perms.sh
#

. cwt/bootstrap.sh

u_instance_set_permissions
