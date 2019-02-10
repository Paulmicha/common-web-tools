#!/usr/bin/env bash

##
# Implements hook -a 'init' -v 'PROVISION_USING HOST_TYPE INSTANCE_TYPE'.
#
# @see u_d4d_write_local_settings() in cwt/extensions/docker4drupal/docker4drupal.inc.sh
# @see u_instance_init() in cwt/instance/instance.inc.sh
#

u_d4d_write_local_settings
