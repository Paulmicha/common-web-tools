#!/usr/bin/env bash

##
# Implements hook -a 'init' -v 'PROVISION_USING INSTANCE_TYPE HOST_TYPE'.
#
# Reacts to "instance init" for project instances using 'docker-compose' as
# provisioning method ($PROVISION_USING).
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
  exit 1
fi

# (Re)init destination file (make empty).
echo -n '' > "$docker_compose_env_file"

# Write every aggregated globals.
for global_name in ${GLOBALS['.sorting']}; do
  u_str_split1 evn_arr $global_name '|'
  global_name="${evn_arr[1]}"
  eval "[[ -z \"\$$global_name\" ]] && echo \"$global_name\"= >> \"$docker_compose_env_file\""
  eval "[[ -n \"\$$global_name\" ]] && echo \"$global_name=\$$global_name\" >> \"$docker_compose_env_file\""
done

echo "Writing docker-compose settings in $docker_compose_env_file : done."
echo
