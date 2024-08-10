#!/usr/bin/env bash

##
# Convenience make task to list available actions in current project instance.
#
# @see Makefile
# @see cwt/make/default.mk
#
# @example
#   make list-actions
#   # Or :
#   cwt/instance/list_actions.sh
#

. cwt/bootstrap.sh

u_cwt_get_actions
u_array_qsort "${cwt_action_names[@]}"

for val in "${sorted_arr[@]}"; do
  printf "%s\n" "$val"
done
