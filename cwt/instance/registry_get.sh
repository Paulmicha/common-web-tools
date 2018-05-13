#!/usr/bin/env bash

##
# [abstract] Gets instance-level registry value.
#
# Reads from an abstract instance-level storage by given key. "Abstract" means that
# CWT core itself doesn't provide any actual implementation for this
# functionality. It is necessary to use an extension which does. E.g. :
# @see cwt/extensions/file_registry
#
# @example
#   cwt/instance/registry_get.sh my_key
#

. cwt/bootstrap.sh
u_instance_registry_get "$@"
echo "$reg_val"
