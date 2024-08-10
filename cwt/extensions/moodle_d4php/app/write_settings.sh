#!/usr/bin/env bash

##
# (Re)write Moodle local settings.
#
# @see cwt/extensions/moodle_d4php/moodle_d4php.inc.sh
#
# Usage :
# make app-write-settings
# # Or :
# cwt/extensions/moodle_d4php/app/write_settings.sh
#

. cwt/bootstrap.sh

u_db_set
u_moodle_write_settings
