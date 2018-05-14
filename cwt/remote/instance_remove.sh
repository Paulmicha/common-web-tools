#!/usr/bin/env bash

##
# CWT remote instance remove action.
#
# @example
#   cwt/remote/instance_remove.sh 'my_short_id'
#

. cwt/bootstrap.sh

# Basic sanitizing (removes characters not in . a-z A-Z 0-9 _ -).
p_id="$1"
p_id=${p_id//[^a-zA-Z0-9_\-\.]/}

conf="cwt/remote/instances/${p_id}.sh"

if [[ -f "$conf" ]]; then
  rm "$conf"
fi
