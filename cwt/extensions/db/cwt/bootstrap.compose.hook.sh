#!/usr/bin/env bash

##
# Implements hook -s 'cwt' -a 'bootstrap' -v 'PROVISION_USING'.
#
# When using the docker-compose extension, we need to make available the DB env
# vars that may not be implemented using globals, as any call to the 'docker
# compose' command may need them.
#
# This file is dynamically included when the "hook" is triggered.
# @see cwt/bootstrap.sh
#

u_db_set_all
