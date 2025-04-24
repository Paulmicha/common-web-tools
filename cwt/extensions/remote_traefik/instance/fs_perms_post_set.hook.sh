#!/usr/bin/env bash

##
# Implements hook -s 'app instance' -a 'fs_perms_post_set' -v 'STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE'
#
# Workaround error permissions 755 for acme.json are too open, please use 600.
#
# @see u_instance_set_permissions()
#

if [[ -f "$PROJECT_DOCROOT/scripts/cwt/local/acme.json" ]]; then
  chmod 600 "$PROJECT_DOCROOT/scripts/cwt/local/acme.json"
fi
