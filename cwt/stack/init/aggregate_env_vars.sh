#!/bin/bash

##
# Aggregates and sorts env vars.
#
# @see cwt/stack/init.sh
#

# Start by including CWT globals.
. cwt/env/vars.sh

# Extract the variables which may be used in subsequent vars.
u_exec_foreach_env_vars u_assign_env_value

# Include any existing matching models.
u_env_models_get_lookup_paths

if [[ $P_VERBOSE == 1 ]]; then
  u_print_env_models_lookup_paths
fi

for env_model in "${ENV_MODELS_PATHS[@]}"; do
  if [[ -f "$env_model" ]]; then
    . "$env_model"

    # For now we prefer to re-process every global, every time we find a new
    # model to include in order to allow conditional declarations in them (i.e.
    # useful for settings that need to adapt/react to each other).
    u_exec_foreach_env_vars u_assign_env_value
  fi
done
