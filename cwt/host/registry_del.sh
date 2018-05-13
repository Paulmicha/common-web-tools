#!/usr/bin/env bash

##
# [abstract] Deletes host-level registry value.
#
# Removes given entry from an abstract host-level storage by given key.
# "Abstract" means that CWT core itself doesn't provide any actual
# implementation for this functionality. It is necessary to use an extension
# which does. E.g. :
# @see cwt/extensions/file_registry
#
# @example
#   cwt/host/registry_del.sh my_key
#

. cwt/bootstrap.sh
u_host_registry_del "$@"
