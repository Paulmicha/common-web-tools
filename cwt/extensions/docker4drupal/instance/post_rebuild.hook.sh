#!/usr/bin/env bash

##
# Implements hook -s 'instance' -p 'post' -a 'rebuild' -v 'PROVISION_USING HOST_TYPE INSTANCE_TYPE'
#
# Rewrite Drupal local settings file.
#
# @see cwt/instance/rebuild.sh
# @see cwt/extensions/docker4drupal/docker4drupal.inc.sh
#

u_d4d_write_local_settings
