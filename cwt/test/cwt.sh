#!/usr/bin/env bash

##
# CWT core tests entry point (subject test / action cwt).
#
# Triggers the `test cwt` hook so core and enabled extensions can run low-level
# checks that validate the base stack on the current host/instance.
#
# @see cwt/test/cwt.hook.sh
#
# @example
#   make test-cwt
#   # Or :
#   cwt/test/cwt.sh
#

. cwt/bootstrap.sh

hook -s 'test' -a 'cwt' -v 'PROVISION_USING HOST_TYPE HOST_OS'
