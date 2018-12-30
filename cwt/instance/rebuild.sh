#!/usr/bin/env bash

##
# [abstract] Triggers a generic 'rebuild' operation for this project instance.
#
# Attention : the 'rebuild' action triggers a 'pre'-prefixed hook before
# triggering the normal (unprefixed) hook.
#
# This script provides an entry point for triggering a specific hook. "Abstract"
# means that CWT core itself doesn't provide any actual implementation for this
# functionality. In order for this script to have any effect, it is necessary
# to use an extension that does.
#
# To list all the possible paths that can be used - among which existing files
# will be sourced when the hook is triggered, use :
# $ make hook-debug s:instance p:pre a:rebuild v:PROVISION_USING HOST_TYPE INSTANCE_TYPE
# $ make hook-debug s:instance a:rebuild v:PROVISION_USING HOST_TYPE INSTANCE_TYPE
#
# @example
#   make rebuild
#   # Or :
#   cwt/instance/rebuild.sh
#

. cwt/bootstrap.sh

hook -s 'instance' -p 'pre' -a 'rebuild' -v 'PROVISION_USING HOST_TYPE INSTANCE_TYPE'
hook -s 'instance' -a 'rebuild' -v 'PROVISION_USING HOST_TYPE INSTANCE_TYPE'
