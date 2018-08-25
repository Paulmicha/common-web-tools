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

# Make the automatic crontab setup for Drupal cron on local host during 'app
# install' opt-in.
global D4D_USE_CRONTAB "[default]=false"

# [optional] Shorter generated make tasks names.
# @see u_instance_task_name() in cwt/instance/instance.inc.sh
global CWT_MAKE_TASKS_SHORTER "[append]='docker4drupal/d4d'"

# Add custom 'make' entry points (CLI shortcuts).
# @see cwt/extensions/docker4drupal/cli/drush.make.sh
# @see cwt/extensions/docker4drupal/cli/drupal.make.sh
# @see cwt/extensions/docker4drupal/cli/composer.make.sh
global CWT_MAKE_INC "[append]='cwt/extensions/docker4drupal/make.mk'"

# Customizable list of global env vars automatically replaceable in generated
# local settings file for Drupal.
# @see u_d4d_write_local_settings() in cwt/extensions/docker4drupal/docker4drupal.inc.sh
global D4D_SETTINGS_GLOBALS "[append]=DRUPAL_HASH_SALT"
global D4D_SETTINGS_GLOBALS "[append]=DRUPAL_FILES_DIR"
global D4D_SETTINGS_GLOBALS "[append]=DRUPAL_PRIVATE_DIR"
global D4D_SETTINGS_GLOBALS "[append]=DRUPAL_TMP_DIR"
global D4D_SETTINGS_GLOBALS "[append]=DRUPAL_CONFIG_SYNC_DIR"

# TODO [debt] The easiest way I could think of doing automatic path translation
# between host filesystem and container filesystem paths involves adding
# yet another global - e.g. APP_DOCROOT_DOCKER - and convert as needed
# @see u_fs_relative_path() in cwt/utilities/fs.sh
# -> postponed. Meanwhile, use additional globals (suffixed like below).
global D4D_SETTINGS_GLOBALS "[append]=DRUPAL_FILES_DIR_C"
global D4D_SETTINGS_GLOBALS "[append]=DRUPAL_PRIVATE_DIR_C"
global D4D_SETTINGS_GLOBALS "[append]=DRUPAL_TMP_DIR_C"
global D4D_SETTINGS_GLOBALS "[append]=DRUPAL_CONFIG_SYNC_DIR_C"
