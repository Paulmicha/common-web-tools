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
# $ . cwt/extensions/mysql/db/get_credentials.sh
#

# TODO [wip] refacto in progress.
# u_db_get_credentials