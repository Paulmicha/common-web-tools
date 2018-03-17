#!/usr/bin/env bash

##
# App instance installation.
#
# This script is a generic example of a common app action.
#
# The predefined hook call below represents an operation meant to setup the
# application if it requires e.g. a database to be initialiazed, an initial DB
# dump to be imported, etc.
#
# @prereq stack services must be running (stack/start).
#
# @example
#   cwt/app/install.sh
#

. cwt/bootstrap.sh

hook -a 'install' -s 'app'

# Allow custom complements for this script.
u_autoload_get_complement "$BASH_SOURCE"
