#!/usr/bin/env bash

##
# Implements hook -s 'instance' -p 'pre' -a 'destroy' -v 'PROVISION_USING HOST_TYPE INSTANCE_TYPE'
#
# Makes sure DB-related env. vars. get exported for extensions which need them
# during this action - e.g. docker-compose.
#
# @see cwt/instance/destroy.sh
# @see cwt/extensions/docker-compose/instance/destroy.docker-compose.hook.sh
#

u_db_set_all
