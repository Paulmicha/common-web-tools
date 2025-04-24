#!/usr/bin/env bash

##
# Implements hook -p 'post' -a 'init' -v 'STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE'.
#
# @see u_moodle_write_settings() in cwt/extensions/moodle_d4php/moodle_d4php.inc.sh
# @see u_instance_init() in cwt/instance/instance.inc.sh
#

u_moodle_write_settings
