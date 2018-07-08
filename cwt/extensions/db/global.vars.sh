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

global CWT_DB_MODE "[default]=none [help]='Specifies if CWT should handle DB credentials, and how. Possible values are none = credentials are handled externally, auto = local instance DB credentials are automatically generated (using random password), or manual = requests values once (using interactive terminal prompts).'"

global CWT_DB_DUMPS_BASE_PATH "[default]=$PROJECT_DOCROOT/dumps"
global WRITEABLE_DIRS "[append]=$CWT_DB_DUMPS_BASE_PATH"
