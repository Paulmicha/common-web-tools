#!/usr/bin/env bash

##
# Global (env) vars for the 'docker4drupal' CWT extension.
#
# This file is used during "instance init" to generate the global environment
# variables specific to current project instance.
#
# @see u_instance_init() in cwt/instance/instance.inc.sh
# @see cwt/utilities/global.sh
# @see cwt/bootstrap.sh
#

# [optional] Shorter generated make tasks names.
# @see u_instance_task_name() in cwt/instance/instance.inc.sh
global CWT_MAKE_TASKS_SHORTER "[append]='docker4drupal/d4d'"

# Add custom 'make' entry points (CLI shortcuts).
# @see cwt/extensions/docker4drupal/cli/drush.make.sh
# @see cwt/extensions/docker4drupal/cli/drupal.make.sh
global CWT_MAKE_INC "[append]='cwt/extensions/docker4drupal/make.mk'"
