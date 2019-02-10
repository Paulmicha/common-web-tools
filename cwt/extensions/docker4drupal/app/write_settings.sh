#!/usr/bin/env bash

##
# (Re)write Drupal local settings.
#
# @see cwt/extensions/docker4drupal/docker4drupal.inc.sh
#
# Usage :
# make app-write-settings
# # Or :
# cwt/extensions/docker4drupal/app/write_settings.sh
#

. cwt/bootstrap.sh

u_d4d_write_local_settings
