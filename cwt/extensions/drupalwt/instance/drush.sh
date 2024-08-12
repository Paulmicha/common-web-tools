#!/usr/bin/env bash

##
# Convenience 'make' shortcut : drush.
#
# Depends on drush (or an alias) being operational on current instance.
#
# @see cwt/extensions/drupalwt/make.mk
#
# @example
#   make drush st
#   # Or :
#   cwt/extensions/drupalwt/instance/drush.sh st
#

. cwt/bootstrap.sh

drush $@
