#!/usr/bin/env bash

##
# [abstract] CWT instance registry_set action.
#
# Allows extensions to implement storing values by key for current project
# instance.
#
# @see hook()
#
# @example
#   cwt/instance/registry_set.sh my_key 'my value'
#

. cwt/bootstrap.sh

# It's easier to set variables in current scope than sending and parsing args to
# any potentially matching lookup paths' sourced files.
# @see hook()
P_REG_KEY="$1"
P_REG_VAL=$2

# Allows empty values (in which case this entry acts as a boolean flag).
if [[ -z "$P_REG_VAL" ]]; then
  P_REG_VAL=1
fi

u_hook_most_specific -s 'instance' -a 'registry_set' -v 'HOST_TYPE'
