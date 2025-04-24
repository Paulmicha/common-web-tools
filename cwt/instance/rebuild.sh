#!/usr/bin/env bash

##
# [abstract] Triggers a generic 'rebuild' operation for this project instance.
#
# This script provides an entry point for triggering a specific hook. "Abstract"
# means that CWT core itself doesn't provide any actual implementation for this
# functionality. In order for this script to have any effect, it is necessary
# to use an extension that does.
#
# The 'rebuild' action triggers a 'pre'-prefixed hook before triggering the
# normal (unprefixed) hook. Same after ('post'-prefixed hook).
#
# To list all the possible paths that can be used among which existing files
# will be sourced when the hook is triggered, run (in this order) :
# $ make hook-debug s:instance p:prepre a:rebuild v:STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE
# $ make hook-debug s:instance p:pre a:rebuild v:STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE
# $ make hook-debug s:instance a:rebuild v:STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE
# $ make hook-debug s:instance p:post a:rebuild v:STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE
#
# @example
#   make rebuild
#   # Or :
#   cwt/instance/rebuild.sh
#

. cwt/bootstrap.sh

# Introduce another step to get the order of operations right in the case of
# docker compose rebuild (i.e. reinitialization should run AFTER docker compose
# stop, and BEFORE rebuild and start).
# @see cwt/instance/pre_rebuild.hook.sh
# @see cwt/extensions/docker-compose/instance/prepre_rebuild.docker-compose.hook.sh
# @see cwt/extensions/docker-compose/instance/rebuild.docker-compose.hook.sh
hook -s 'instance' -p 'prepre' -a 'rebuild' -v 'STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE'
hook -s 'instance' -p 'pre' -a 'rebuild' -v 'STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE'
hook -s 'instance' -a 'rebuild' -v 'STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE'
hook -s 'instance' -p 'post' -a 'rebuild' -v 'STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE'
