#!/usr/bin/env bash

##
# Implements hook -s 'instance' -p 'pre' -a 'rebuild' -v 'STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE'
#
# Makes sure DB-related env. vars. get exported for extensions which need them
# during this action - e.g. docker-compose.
#
# @see cwt/instance/rebuild.sh
# @see cwt/extensions/compose/instance/rebuild.compose.hook.sh
#

u_db_set_all
