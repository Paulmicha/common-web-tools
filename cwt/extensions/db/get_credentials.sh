#!/usr/bin/env bash

##
# Gets local instance DB credentials.
#
# This script initializes a random password the first time it is called (but
# not on subsequent calls). It is idempotent.
#
# @requires cwt/bootstrap.sh
# @requires global $INSTANCE_DOMAIN in scope.
#
# Usage :
# $ . cwt/db/get_credentials.sh
#

u_db_get_credentials
