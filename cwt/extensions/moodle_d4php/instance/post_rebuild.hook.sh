#!/usr/bin/env bash

##
# Implements hook -s 'instance' -p 'post' -a 'rebuild' -v 'STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE'
#
# Rewrite Moodle local settings file.
#
# @see cwt/instance/rebuild.sh
# @see cwt/extensions/moodle_d4php/moodle_d4php.inc.sh
#

u_moodle_write_settings
