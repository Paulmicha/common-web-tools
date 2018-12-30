#!/usr/bin/env bash

##
# [abstract] Triggers a generic compilation action in current app instance.
#
# This script provides an entry point for triggering a specific hook. "Abstract"
# means that CWT core itself doesn't provide any actual implementation for this
# functionality. In order for this script to have any effect, it is necessary
# to use an extension that does.
#
# To list all the possible paths that can be used - among which existing files
# will be sourced when the hook is triggered, use :
# $ make hook-debug s:app a:compile v:PROVISION_USING HOST_TYPE INSTANCE_TYPE
#
# @example
#   make app-compile
#   # Or :
#   cwt/app/compile.sh
#

. cwt/bootstrap.sh

hook -s 'app' -a 'compile' -v 'PROVISION_USING HOST_TYPE INSTANCE_TYPE'
