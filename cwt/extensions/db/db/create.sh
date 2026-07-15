#!/usr/bin/env bash

##
# [abstract] Creates (+ sets up) new database.
#
# "Abstract" means that this extension doesn't provide any actual implementation
# for this functionality. It is necessary to use an extension that does. E.g. :
#
# @see cwt/extensions/mysql
# @see cwt/extensions/pgsql
#
# To list all the possible paths that can be used, use :
# $ make hook-debug s:db a:create v:DB_DRIVER HOST_TYPE INSTANCE_TYPE
#
# To check the most specific match (if any is found) :
# $ make hook-debug ms s:db a:create v:DB_DRIVER HOST_TYPE INSTANCE_TYPE
#
# @param 1 [optional] String : the database ID ($DB_ID), see u_db_set().
#   Defaults to 'default'.
# @param 2 [optional] String : force reload flag (bypasses optimization) if the
#   DB credentials vars are already exported in current shell scope.
#   TODO deprecate this argument and export a specific variable instead.
#
# @example
#   make db-create
#   make db-create 'custom_db_id'
#   # Or :
#   cwt/extensions/db/db/create.sh
#   cwt/extensions/db/db/create.sh 'custom_db_id'
#

. cwt/bootstrap.sh

# @see cwt/extensions/db/db.inc.sh
u_db_create $@
