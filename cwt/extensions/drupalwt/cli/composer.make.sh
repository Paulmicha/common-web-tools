#!/usr/bin/env bash

##
# Convenience 'make' shortcut : composer.
#
# Depends on composer (or an alias) being operational on current instance.
#
# @see cwt/extensions/drupalwt/make.mk
#
# @example
#   make composer update nothing
#   # Or :
#   cwt/extensions/drupalwt/cli/composer.make.sh update nothing
#

. cwt/bootstrap.sh

composer $@
