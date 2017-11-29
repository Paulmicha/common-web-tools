#!/bin/bash

##
# Implements stack post init hook.
#
# This script is automatically sourced by another script.
# @see cwt/stack/init.sh
# @see cwt/utilities/hook.sh
#

# Write env vars to docker-compose specific ".env" file (in project root dir).
docker_compose_env_file='.env'

# First make sure we have something to write.
if [[ -z "$ENV_VARS_COUNT" ]]; then
  echo
  echo "Error in $BASH_SOURCE line $LINENO: nothing to write."
  echo "Aborting (1)."
  echo
  return 1
fi

# Confirm overwriting existing env file if it already exists.
if [[ ($P_YES == 0) && (-f "$docker_compose_env_file") ]]; then
  echo
  while true; do
    read -p "Override existing docker-compose env file ? (y/n) : " yn
    case $yn in
      [Yy]* ) echo "Ok, proceeding to override docker-compose env file."; break;;
      [Nn]* ) echo "Aborting (3)."; return 3;;
      * ) echo "Please answer yes (enter 'y') or no (enter 'n').";;
    esac
  done
fi

# (Re)init destination file (make empty).
echo '' > "$docker_compose_env_file"

# Write every aggregated globals.
# @see cwt/stack/init/aggregate_env_vars.sh
for env_var_name in ${ENV_VARS['.sorting']}; do
  u_str_split1 evn_arr $env_var_name '|'
  env_var_name="${evn_arr[1]}"
  eval "[[ -z \"\$$env_var_name\" ]] && echo \"$env_var_name\"= >> \"$docker_compose_env_file\""
  eval "[[ -n \"\$$env_var_name\" ]] && echo \"$env_var_name=\$$env_var_name\" >> \"$docker_compose_env_file\""
done
