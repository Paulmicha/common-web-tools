#!/usr/bin/env bash

##
# [abstract] Starts watchers in current app instance.
#
# "Watchers" are programs running continuously in the background to react upon
# code modifications. They usually compile source files when they are modified.
#
# This script provides an entry point for triggering a specific hook. "Abstract"
# means that CWT core itself doesn't provide any actual implementation for this
# functionality. In order for this script to have any effect, it is necessary
# to use an extension that does.
#
# @example
#   cwt/app/watch_start.sh
#

. cwt/bootstrap.sh

hook -s 'app' -a 'watch_start' -v 'PROVISION_USING HOST_TYPE INSTANCE_TYPE'
