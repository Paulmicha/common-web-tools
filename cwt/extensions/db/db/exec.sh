#!/usr/bin/env bash

##
# [abstract] Executes given file (containing any query) in given DB ID.
#
# "Abstract" means that this extension doesn't provide any actual implementation
# for this functionality. It is necessary to use an extension that does. E.g. :
#
# @see cwt/extensions/mysql
# @see cwt/extensions/pgsql
#
# Important notes : implementations of the hook -s 'db' -a 'dump' MUST use the
# following variable in calling scope as output path (resulting file) :
#
# @var db_dump_file
#
# To list all the possible paths that can be used, use :
# $ make hook-debug s:db a:exec v:DB_DRIVER DB_ID INSTANCE_TYPE PROVISION_USING
#
# To check the most specific match (if any is found) :
# $ make hook-debug ms s:db a:exec v:DB_DRIVER DB_ID INSTANCE_TYPE PROVISION_USING
#
# @param 1 String : the dump file path.
# @param 2 [optional] String : the database ID ($DB_ID), see u_db_set().
#   Defaults to 'default'.
# @param 3 [optional] String : force reload flag (bypasses optimization) if the
#   DB credentials vars are already exported in current shell scope.
#   TODO deprecate this argument and export a specific variable instead.
#
# @example
#   make db-exec 'path/to/file.sql'
#   make db-exec 'path/to/file.sql' 'custom_db_id'
#   # Or :
#   cwt/extensions/db/db/exec.sh 'path/to/file.sql'
#   cwt/extensions/db/db/exec.sh 'path/to/file.sql' 'custom_db_id'
#

. cwt/bootstrap.sh

# @see cwt/extensions/db/db.inc.sh
u_db_exec $@
