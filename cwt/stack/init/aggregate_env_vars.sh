#!/usr/bin/env bash

##
# Aggregates env vars.
#
# This process consists in :
# - including any existing matching includes
# - exporting each variable defined in them as global
# - assigning their value - either by terminal prompt, or a default values if
#   no matching argument is found
#
# @see cwt/stack/init.sh
#

u_global_get_includes_lookup_paths

if [[ $P_VERBOSE == 1 ]]; then
  u_autoload_print_lookup_paths GLOBALS_INCLUDES_PATHS "Env includes"
fi

for vars_file in "${GLOBALS_INCLUDES_PATHS[@]}"; do
  if [[ -f "$vars_file" ]]; then
    . "$vars_file"
  fi
  u_autoload_get_complement "$vars_file"
done
