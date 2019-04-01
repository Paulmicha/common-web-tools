#!/usr/bin/env bash

##
# Implements hook -s 'app instance' -a 'fs_ownership_get' -v 'PROVISION_USING HOST_TYPE INSTANCE_TYPE'
#
# This file is dynamically included when the "hook" is triggered.
# @see u_instance_get_ownership() in cwt/instance/instance.inc.sh
#
# To verify which files can be used (and will be sourced) when this hook is
# triggered :
# $ make hook-debug s:app instance a:fs_ownership_get v:PROVISION_USING HOST_TYPE INSTANCE_TYPE
#

# TODO [wip] Update this to match latest upstream changes in drupalwt.
# User 82 is www-data in Docker images like wodby/drupal-php.
FS_W_OWNER='82'
