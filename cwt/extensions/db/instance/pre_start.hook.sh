#!/usr/bin/env bash

##
# Implements hook -s 'instance' -p 'pre' -a 'start' -v 'PROVISION_USING HOST_TYPE INSTANCE_TYPE'
#
# Makes sure DB-related env. vars. get exported for extensions which need them
# during this action - e.g. docker-compose.
#
# @see cwt/instance/start.sh
# @see cwt/extensions/docker-compose/instance/start.docker-compose.hook.sh
#

u_db_set
