#!/usr/bin/env bash

##
# Implements hook -s 'cwt' -a 'alias' -v 'PROVISION_USING'.
#
# Declares default bash aliases for current project instance using drush *with*
# docker compose provisionning. If that's *not* the case, the other
# implementation will be loaded instead :
#
# @see cwt/extensions/drush/cwt/alias.hook.sh
#
# This file is dynamically included when the "hook" is triggered.
# @see cwt/bootstrap.sh
#
# Uses the docker exec interactive flag from 'docker-compose' extension.
# @see cwt/extensions/docker-compose/cwt/pre_bootstrap.docker-compose.hook.sh
#
# In order to support multi-db projects, those aliases must target the proper
# service depending on the currently selected DB_ID.
#
# This hook will be called once during bootstrap, then once more during "db set"
# where a local variable may be used to overwrite those aliases in order to
# target the correct service.
#
# By default, the target container name will be the DRUSH_SERVICE_NAME value.
#
# @see cwt/extensions/drush/cwt/global.docker-compose.vars.sh
# @see u_db_set() in cwt/extensions/db/db.inc.sh
#

if [[ -z "$dc_drush_service_name" ]]; then
  dc_drush_service_name="$DRUSH_SERVICE_NAME"
fi

if [[ -n "$dc_drush_service_name" ]]; then
  # Debug.
  # echo "$BASH_SOURCE line $LINENO"
  # echo "  aliases set or updated :"

  if [[ -n "$SERVER_DOCROOT_C" ]]; then
    alias drush="docker compose exec $DC_TTY $dc_drush_service_name $DRUSH_BIN --root='$SERVER_DOCROOT_C'"

    # Debug.
    # echo "    drush = docker compose exec $DC_TTY $dc_drush_service_name $DRUSH_BIN --root='$SERVER_DOCROOT_C'"
    # echo
  else
    alias drush="docker compose exec $DC_TTY $dc_drush_service_name $DRUSH_BIN"

    # Debug.
    # echo "    drush = docker compose exec $DC_TTY $dc_drush_service_name $DRUSH_BIN"
    # echo
  fi
fi
