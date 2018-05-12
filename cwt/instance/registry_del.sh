#!/usr/bin/env bash

##
# [abstract] Deletes instance-level registry value.
#
# Removes given entry from an abstract instance-level storage by given key.
# "Abstract" means that CWT core itself doesn't provide any actual
# implementation for this functionality. It is necessary to use an extension
# which does. E.g. :
# @see cwt/extensions/file_registry
#
# @example
#   cwt/instance/registry_del.sh my_key
#

. cwt/bootstrap.sh
u_instance_registry_del $@
