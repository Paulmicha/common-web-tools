#!/usr/bin/env bash

##
# [abstract] Executes given query in given DB ID.
#
# "Abstract" means that this extension doesn't provide any actual implementation
# for this functionality. It is necessary to use an extension that does. E.g. :
#
# @see cwt/extensions/mysql
# @see cwt/extensions/pgsql
#
# To list all the possible paths that can be used, use :
# $ make hook-debug s:db a:query v:DB_DRIVER DB_ID INSTANCE_TYPE PROVISION_USING
#
# To check the most specific match (if any is found) :
# $ make hook-debug ms s:db a:query v:DB_DRIVER DB_ID INSTANCE_TYPE PROVISION_USING
#
# @param 1 String : the dump file path.
# @param 2 [optional] String : the database ID ($DB_ID), see u_db_set().
#   Defaults to 'default'.
# @param 3 [optional] String : force reload flag (bypasses optimization) if the
#   DB credentials vars are already exported in current shell scope.
#   TODO deprecate this argument and export a specific variable instead.
#
# @example
#   cwt/extensions/db/db/query.sh 'UPDATE users SET name = "foobar" WHERE email = "foo@bar.com";'
#

. cwt/bootstrap.sh

# @see cwt/extensions/db/db.inc.sh
u_db_query $@
