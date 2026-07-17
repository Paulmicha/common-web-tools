#!/usr/bin/env bash

##
# Software setup: same apply path as host-provision (manifest diff → install).
#
# Accepts --prune (or SOFTWARE_PRUNE=1) for opt-in uninstall of managed extras.
#
# @example
#   make software-setup
#   make software-setup -- --prune
#   # Or :
#   cwt/extensions/software/software/setup.sh --prune
#

. cwt/bootstrap.sh

u_software_parse_args "$@"
u_software_provision apply
