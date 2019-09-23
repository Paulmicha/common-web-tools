#!/usr/bin/env bash

##
# Global (env) vars for the 'db' CWT extension.
#
# This file is used during "instance init" to generate the global environment
# variables specific to current project instance.
#
# @see u_instance_init() in cwt/instance/instance.inc.sh
# @see cwt/utilities/global.sh
# @see cwt/bootstrap.sh
#

global CWT_DB_IDS "[default]=default [help]='Allows project instances to use several databases. By default, a single database ID is used : ’default’. These are used to differenciate DB settings and credentials and for automatic routine backup dump file paths - see u_db_routine_backup(). For declaring more database(s), use only space-separated strings, ex: ’default mig_buffer’.'"

global CWT_DB_MODE "[default]=auto [help]='Specifies if CWT should handle DB credentials, and how. Possible values are none = credentials are already available i.e. as local env vars, auto = local instance DB credentials are automatically generated (using random password), or manual = requests values once using interactive terminal prompts during instance init.'"

global CWT_DB_DUMPS_BASE_PATH "[default]=$PROJECT_DOCROOT/data/db-dumps [help]='This folder will contain DB dump files from local instance, but it also may contain dumps from remote instances (used during sync operations, see remote extension). In this folder, it is recommended to follow a directory structure by instance and database ID - ex: ’data/db-dumps/local/default’, which is the convention used for automatic routine backup dump file paths. See u_db_routine_backup().'"

global CWT_DB_INITIAL_IMPORT "[default]=true [help]='Set to true to import the first dump file whose name matches « initial.* » found in CWT_DB_DUMPS_BASE_PATH (i.e. $CWT_DB_DUMPS_BASE_PATH) during app install / instance setup. See cwt/app/install.sh and cwt/instance/setup.sh'"

# Workaround minor issue when listing all paths for driver-specific hooks, e.g.
# $ make hook-debug s:db a:exists v:DB_DRIVER HOST_TYPE INSTANCE_TYPE
# This does not affect the "real" call, only the debug utility (because these
# hooks are called after u_db_get_credentials in the same scope).
global DB_DRIVER "[default]='mysql'"
