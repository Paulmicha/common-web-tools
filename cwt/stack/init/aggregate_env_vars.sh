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
for env_model in "${ENV_MODELS_PATHS[@]}"; do
  if [[ -f "$env_model" ]]; then
    . "$env_model"

    # For now we prefer to re-process every global, every time we found a new
    # model to include in order to allow for conditional declarations in them.
    u_exec_foreach_env_vars u_assign_env_value
  fi
done

for env_var_name in ${ENV_VARS['.sorting']}; do
  u_str_split1 evn_arr $env_var_name '|'
  env_var_name="${evn_arr[1]}"

  eval "echo \"env_var_name $env_var_name = '\$$env_var_name'\"";

  # for key in ${ENV_VARS_UNIQUE_KEYS[@]}; do
  #   val="${ENV_VARS[$env_var_name|$key]}"

  #   if [[ -n "$val" ]]; then
  #     echo "${env_var_name}.${key} = ${ENV_VARS[${env_var_name}|${key}]}";
  #   fi
  # done
done
