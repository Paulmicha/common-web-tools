#!/usr/bin/env bash

##
# Software update: alias of apply (upgrade outdated pinned tools).
#
# @example
#   make software-update
#   # Or :
#   cwt/extensions/software/software/update.sh
#

. cwt/bootstrap.sh

u_software_parse_args "$@"
u_software_provision apply
