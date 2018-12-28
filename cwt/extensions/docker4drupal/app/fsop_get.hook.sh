#!/usr/bin/env bash

##
# Implements hook -s 'app instance' -a 'fsop_get' -v 'PROVISION_USING HOST_TYPE INSTANCE_TYPE'
#
# This file is dynamically included when the "hook" is triggered.
# @see u_instance_get_permissions() in cwt/instance/instance.inc.sh
#

# User 82 is www-data in Docker images like wodby/drupal-php.
FS_W_OWNER='82'
