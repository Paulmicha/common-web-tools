#!/usr/bin/env bash

##
# Convenience 'make' shortcut : drush.
#
# Depends on drush (or an alias) being operational on current instance.
#
# @see cwt/extensions/docker4drupal/make.mk
#
# @example
#   make drush st
#   # Or :
#   cwt/extensions/docker4drupal/cli/drush.make.sh st
#

. cwt/bootstrap.sh

drush $@
