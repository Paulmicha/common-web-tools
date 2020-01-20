#!/usr/bin/env bash

##
# (Re)write Drupal local settings.
#
# @see cwt/extensions/drupalwt/drupalwt.inc.sh
#
# Usage :
# make app-write-settings
# # Or :
# cwt/extensions/drupalwt/app/write_settings.sh
#

. cwt/bootstrap.sh

u_db_set
u_dwt_write_settings
