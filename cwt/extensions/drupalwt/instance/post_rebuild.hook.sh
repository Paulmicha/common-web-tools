#!/usr/bin/env bash

##
# Implements hook -s 'instance' -p 'post' -a 'rebuild' -v 'PROVISION_USING HOST_TYPE INSTANCE_TYPE'
#
# Rewrite Drupal local settings file.
#
# @see cwt/instance/rebuild.sh
# @see cwt/extensions/drupalwt/drupalwt.inc.sh
#

u_dwt_write_local_settings
