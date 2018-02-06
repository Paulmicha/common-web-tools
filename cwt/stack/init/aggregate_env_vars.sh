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

# Allow extra env vars file at the root of custom dir, *after* dynamic lookups.
if [[ -f "$CWT_CUSTOM_DIR/global.vars.sh" ]]; then
  . "$CWT_CUSTOM_DIR/global.vars.sh"
fi

# Support deferred value assignation.
# @see global()
if [[ "${GLOBALS['.defer-max']}" -gt '0' ]]; then
  i=0
  max="${GLOBALS['.defer-max']}"
  for (( i=1; i<=$max; i++ )); do
    for global_name in ${GLOBALS[".defer-$i"]}; do
      u_global_assign_value "$global_name"
    done
  done
fi
