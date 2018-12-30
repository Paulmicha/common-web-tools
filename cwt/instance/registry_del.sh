#!/usr/bin/env bash

##
# [abstract] Deletes instance-level registry value.
#
# Removes given entry from an abstract instance-level storage by given key.
#
# This script provides an entry point for triggering a specific hook. "Abstract"
# means that CWT core itself doesn't provide any actual implementation for this
# functionality. In order for this script to have any effect, it is necessary
# to use an extension that does. E.g. :
# @see cwt/extensions/file_registry
#
# @example
#   make reg-del
#   # Or :
#   cwt/instance/registry_del.sh my_key
#

. cwt/bootstrap.sh
u_instance_registry_del "$@"
