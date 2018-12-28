#!/usr/bin/env bash

##
# Convenience 'make' shortcut : drupal console.
#
# Depends on drupal console (or an alias) being operational on current instance.
#
# @see cwt/extensions/docker4drupal/make.mk
#
# @example
#   make drupal 'config:import:single --file="../config/split/dev/config_split.config_split.dev.yml"'
#   # Or :
#   cwt/extensions/docker4drupal/cli/drupal.make.sh config:import:single --file="../config/split/dev/config_split.config_split.dev.yml"
#

. cwt/bootstrap.sh

drupal $@