#!/bin/bash

##
# Aggregates and sorts env vars.
#
# @see cwt/stack/init.sh
#

u_env_models_get_lookup_paths

# Start with CWT globals.
. cwt/env/vars.sh

# TODO : sort and extract variables before the rest.

# Include any existing matching models.
for env_model in "${ENV_MODELS_PATHS[@]}"; do
  echo "matching model : $env_model"
  if [[ -f "$env_model" ]]; then
    . "$env_model"
  fi
done

# WIP

# for var_name in "${!ENV_VARS[@]}"; do
#   echo "var $var_name = '${ENV_VARS[$var_name]}'"
# done

for env_var_name in ${ENV_VARS['.sorting']}; do
  u_str_split1 evn_arr $env_var_name '|'
  env_var_name="${evn_arr[1]}"
  for key in ${ENV_VARS_KEYS[@]}; do
    echo "${env_var_name}.${key} = ${ENV_VARS[${env_var_name}|${key}]}";
  done
done
