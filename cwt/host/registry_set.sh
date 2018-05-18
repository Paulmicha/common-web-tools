#!/usr/bin/env bash

##
# [abstract] Sets host-level registry value.
#
# Writes to an abstract host-level storage by given key.
#
# This script provides an entry point for triggering a specific hook. "Abstract"
# means that CWT core itself doesn't provide any actual implementation for this
# functionality. In order for this script to have any effect, it is necessary
# to use an extension that does. E.g. :
# @see cwt/extensions/file_registry
#
# @example
#   cwt/host/registry_set.sh my_key 'my value'
#

. cwt/bootstrap.sh
u_host_registry_set "$@"
