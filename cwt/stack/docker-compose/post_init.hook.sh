#!/usr/bin/env bash

##
# Implements stack post init hook.
#
# This script is automatically sourced by another script.
# @see cwt/stack/init.sh
# @see cwt/utilities/hook.sh
#

# Write env vars to docker-compose specific ".env" file (in project root dir).
docker_compose_env_file='.env'

echo "Writing docker-compose settings in $docker_compose_env_file ..."

# First make sure we have something to write.
if [[ -z "$GLOBALS_COUNT" ]]; then
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
echo -n '' > "$docker_compose_env_file"

# Write every aggregated globals.
# @see cwt/stack/init/aggregate_env_vars.sh
for global_name in ${GLOBALS['.sorting']}; do
  u_str_split1 evn_arr $global_name '|'
  global_name="${evn_arr[1]}"
  eval "[[ -z \"\$$global_name\" ]] && echo \"$global_name\"= >> \"$docker_compose_env_file\""
  eval "[[ -n \"\$$global_name\" ]] && echo \"$global_name=\$$global_name\" >> \"$docker_compose_env_file\""
done

echo "Writing docker-compose settings in $docker_compose_env_file : done."
echo
