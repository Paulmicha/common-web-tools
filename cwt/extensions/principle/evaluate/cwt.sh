#!/usr/bin/env bash

##
# CWT core evaluates entry point (subject evaluate / action cwt).
#
# Triggers the `evaluate cwt` hook so core and enabled extensions can run low-level
# checks that validate the base stack on the current host/instance.
#
# @see cwt/extensions/principle/evaluate/cwt.sh
#
# @example
#   make evaluate-cwt
#   # Or :
#   cwt/extensions/principle/evaluate/cwt.sh
#

. cwt/bootstrap.sh

hook -s 'evaluate' -a 'cwt' -v 'PROVISION_USING INSTANCE_TYPE HOST_TYPE HOST_OS'
