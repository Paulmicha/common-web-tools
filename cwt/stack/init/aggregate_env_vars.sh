#!/bin/bash

##
# Aggregates env vars.
#
# @see cwt/stack/init.sh
#

u_env_models_get_lookup_paths

. cwt/env/vars.sh

for env_model in "${ENV_MODELS_PATHS[@]}"; do
  if [[ -f "$env_model" ]]; then
    . "$env_model"
  fi
done

for var_name in "${!ENV_VARS[@]}"; do
  echo "var $var_name = '${ENV_VARS[$var_name]}'"
done
