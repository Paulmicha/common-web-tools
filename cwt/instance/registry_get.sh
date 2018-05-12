#!/usr/bin/env bash

##
# [abstract] CWT instance registry_get action.
#
# Allows extensions to implement reading values by key for current project
# instance.
#
# @see hook()
#
# @example
#   cwt/instance/registry_get.sh my_key
#

. cwt/bootstrap.sh

# It's easier to set variables in current scope than sending and parsing args to
# any potentially matching lookup paths' sourced files.
# @see hook()
P_REG_KEY="$1"

# Any positive match MUST exit with 0 code after printing value to stdin.
# TODO implement "most specific" version of the hook() function - in case there
# are multiple matches (only 1 can "win" in this case).
hook -s 'instance' -a 'registry_get' -v 'HOST_TYPE'

# If we reach this point, it means no match or no value was found.
exit 1
