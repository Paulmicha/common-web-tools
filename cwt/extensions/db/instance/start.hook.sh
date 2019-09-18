#!/usr/bin/env bash

##
# Implements hook -s 'instance' -a 'start' -v 'PROVISION_USING HOST_TYPE INSTANCE_TYPE'
#
# Makes sure DB-related env. vars. get exported for extensions which need them
# during this action - e.g. docker-compose.
#

u_db_get_credentials
