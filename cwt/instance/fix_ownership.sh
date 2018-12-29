#!/usr/bin/env bash

##
# (Re)sets filesystem ownership.
#
# @see u_instance_set_ownership() in cwt/instance/instance.inc.sh
# @see cwt/instance/fs_ownership_set.hook.sh
#
# @example
#   make fix_ownership
#   # Or :
#   cwt/instance/fix_ownership.sh
#

. cwt/bootstrap.sh

u_instance_set_ownership
