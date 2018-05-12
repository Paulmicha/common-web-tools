#!/usr/bin/env bash

##
# [abstract] CWT host registry_get action.
#
# Allows extensions to implement reading values by key "scoped" to the entire
# local host.
#
# @see hook()
#
# @example
#   cwt/host/registry_get.sh my_key
#

. cwt/bootstrap.sh

# It's easier to set variables in current scope than sending and parsing args to
# any potentially matching lookup paths' sourced files.
# @see hook()
P_REG_KEY="$1"

# Failsafe from potential collisions in previous calls.
unset REG_VAL

# Any positive match MUST exit with 0 code after printing value to stdin - or
# setting the REG_VAL variable to the value fetched.
u_hook_most_specific -s 'host' -a 'registry_get' -v 'HOST_TYPE'

# If we reach this point, it means no match or no value was found.
exit 1
