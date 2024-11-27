#!/usr/bin/env bash

##
# List all currently active make entry points.
#
# @see Makefile
# @see cwt/make/default.mk
#
# @example
#   make make-list-entry-points
#   # Or :
#   cwt/make/list_entry_points.sh
#

. cwt/bootstrap.sh

make_entries=()
real_scripts=()
output=()

u_make_list_entry_points

for index in "${!real_scripts[@]}"; do
  task="${make_entries[index]}"
  script="${real_scripts[index]}"

  output+=("$task
  → $script")
done

u_array_qsort "${output[@]}"

for line in "${sorted_arr[@]}"; do
  echo "$line"
done
