#!/usr/bin/env bash

##
# Implements hook -p 'post' -a 'init'.
#
# Idempotent remotes local setup.
# @see cwt/extensions/remote/remote.inc.sh
#
# @example
#   # This gets executed during normal init :
#   scripts/init.sh
#
#   # Can also be run separately - here, in a subshell :
#   (. cwt/bootstrap.sh && . cwt/extensions/remote/instance/post_init.hook.sh)
#

echo "Writing generated remote instance definitions ..."

u_remote_instances_setup

echo "Writing generated remote instance definitions : done."
echo
