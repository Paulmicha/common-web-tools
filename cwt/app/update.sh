#!/usr/bin/env bash

##
# [abstract] Updates current application instance.
#
# The "app update" action is meant to contain all that needs to run when
# updating a project instance (i.e. "receiving" the deployment).
#
# This script provides an entry point for triggering a specific hook. "Abstract"
# means that CWT core itself doesn't provide any actual implementation for this
# functionality. In order for this script to have any effect, it is necessary
# to use an extension that does.
#
# To list all the possible paths that can be used among which existing files
# will be sourced when the hook is triggered, run (in this order) :
# $ make hook-debug s:app p:pre a:update v:PROVISION_USING INSTANCE_TYPE
# $ make hook-debug s:app a:update v:PROVISION_USING INSTANCE_TYPE
# $ make hook-debug s:app p:post a:update v:PROVISION_USING INSTANCE_TYPE
#
# @example
#   make app-update
#   # Or :
#   cwt/app/update.sh
#

. cwt/bootstrap.sh

hook -s 'app' -p 'pre' -a 'update' -v 'PROVISION_USING INSTANCE_TYPE'
hook -s 'app' -a 'update' -v 'PROVISION_USING INSTANCE_TYPE'
hook -s 'app' -p 'post' -a 'update' -v 'PROVISION_USING INSTANCE_TYPE'
