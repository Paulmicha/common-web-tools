#!/bin/bash

##
# Aggregates env vars.
#
# This process consists in :
# - including any existing matching models
# - exporting each variable defined in them as global
# - assigning their value - either by terminal prompt, or a default values if
#   no matching argument is found
#
# @see cwt/stack/init.sh
#

u_env_models_get_lookup_paths

if [[ $P_VERBOSE == 1 ]]; then
  u_autoload_print_lookup_paths ENV_MODELS_PATHS "Env models"
fi

for env_model in "${ENV_MODELS_PATHS[@]}"; do
  if [[ -f "$env_model" ]]; then
    . "$env_model"
    u_autoload_get_complement "$env_model"

    # For now we prefer to re-process every global, every time we find a new
    # model to include. This allows conditional declarations in them (i.e.
    # useful for settings that need to adapt/react to each other).
    u_exec_foreach_env_vars u_assign_env_value
  fi
done
