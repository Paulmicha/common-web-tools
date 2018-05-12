#!/usr/bin/env bash

##
# [abstract] Sets host-level registry value.
#
# Writes to an abstract host-level storage by given key. "Abstract" means that
# CWT core itself doesn't provide any actual implementation for this
# functionality. It is necessary to use an extension which does. E.g. :
# @see cwt/extensions/file_registry
#
# @example
#   cwt/host/registry_set.sh my_key 'my value'
#

. cwt/bootstrap.sh
u_host_registry_set $@
