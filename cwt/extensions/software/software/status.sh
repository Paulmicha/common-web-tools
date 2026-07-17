#!/usr/bin/env bash

##
# Software status: compare manifests to installed tools (no apply).
#
# @example
#   make software-status
#   # Or :
#   cwt/extensions/software/software/status.sh
#

. cwt/bootstrap.sh

u_software_provision status
