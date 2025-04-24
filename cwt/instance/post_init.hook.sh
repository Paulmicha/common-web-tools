#!/usr/bin/env bash

##
# Implements hook -p 'post' -a 'init'.
#
# Warms up the local CWT cache for just a bunch of usual hooks.
#
# @see cwt/bootstrap.sh
# @see cwt/utilities/hook.sh
#
# @example
#   make cwt-cache-warmup
#   # Or :
#   cwt/instance/cwt_cache_warmup.sh
#

echo "Warming up a bunch of CWT hooks cache ..."

hook -w -s 'instance' -p 'pre' -a 'start' -v 'STACK_VERSION STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE'
hook -w -s 'instance' -a 'start' -v 'STACK_VERSION STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE'
hook -w -s 'instance' -p 'post' -a 'start' -v 'STACK_VERSION STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE'
hook -w -s 'instance' -p 'pre' -a 'stop' -v 'STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE'
hook -w -s 'instance' -a 'stop' -v 'STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE'
hook -w -s 'instance' -p 'post' -a 'stop' -v 'STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE'
hook -w -s 'instance' -p 'stage2' -a 'setup' -v 'STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE'
hook -w -s 'instance' -p 'post' -a 'setup' -v 'STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE'

# Hooks related to file ownership & permissions.
# @see cwt/instance/fs_perms_set.hook.sh
# @see cwt/instance/fs_ownership_set.hook.sh
subjects='app'

if [[ -n "$CWT_APPS" ]]; then
  subjects="$CWT_APPS"
fi

actions='
fs_ownership_get
fs_ownership_pre_set
fs_ownership_set
fs_ownership_post_set
fs_perms_get
fs_perms_pre_set
fs_perms_set
fs_perms_post_set
'

for action in $actions; do
  hook -w -s "$subjects instance" -a "$action" -v 'STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE'
done

echo "Warming up a bunch of CWT hooks cache : done."
echo
