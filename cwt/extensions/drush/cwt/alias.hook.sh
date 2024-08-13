#!/usr/bin/env bash

##
# Implements hook -s 'cwt' -a 'alias' -v 'PROVISION_USING'.
#
# Declares default bash aliases for current project instance using drush, but
# *not* using docker-compose. In that case, the other implementation will be
# loaded instead :
#
# @see cwt/extensions/drush/cwt/alias.docker-compose.hook.sh
#
# This file is dynamically included when the "hook" is triggered.
# @see cwt/bootstrap.sh
#
# Uses the docker exec interactive flag from 'docker-compose' extension.
# @see cwt/extensions/docker-compose/cwt/pre_bootstrap.docker-compose.hook.sh
#
# This hook will be called once during bootstrap, then once more during "db set"
# where a local variable may be used to overwrite those aliases in order to
# target the correct service.
#
# @see cwt/extensions/drush/cwt/global.docker-compose.vars.sh
# @see u_db_set() in cwt/extensions/db/db.inc.sh
#

if [[ -d "$SERVER_DOCROOT" ]]; then
  alias drush="drush --root='$SERVER_DOCROOT'"

  # Debug.
  # echo "$BASH_SOURCE line $LINENO"
  # echo "  aliases set or updated :"
  # echo "    drush --root='$SERVER_DOCROOT'"
  # echo
fi
