#!/usr/bin/env bash

##
# [abstract] Triggers a generic 'build' operation for this project instance.
#
# This script provides an entry point for triggering a specific hook. "Abstract"
# means that CWT core itself doesn't provide any actual implementation for this
# functionality. In order for this script to have any effect, it is necessary
# to use an extension that does.
#
# The 'build' action triggers a 'pre'-prefixed hook before triggering the
# normal (unprefixed) hook. Same after ('post'-prefixed hook).
#
# To list all the possible paths that can be used among which existing files
# will be sourced when the hook is triggered, run (in this order) :
# $ make hook-debug s:instance p:pre a:build v:STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE
# $ make hook-debug s:instance a:build v:STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE
# $ make hook-debug s:instance p:post a:build v:STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE
#
# @example
#   make build
#   # Or :
#   cwt/instance/build.sh
#

. cwt/bootstrap.sh

hook -s 'instance' -p 'pre' -a 'build' -v 'STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE'
hook -s 'instance' -a 'build' -v 'STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE'
hook -s 'instance' -p 'post' -a 'build' -v 'STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE'
