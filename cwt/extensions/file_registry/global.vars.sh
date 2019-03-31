#!/usr/bin/env bash

##
# Global (env) vars for the 'file_registry' CWT extension.
#
# This file is used during "instance init" to generate the global environment
# variables specific to current project instance.
#
# @see u_instance_init() in cwt/instance/instance.inc.sh
# @see cwt/utilities/global.sh
# @see cwt/bootstrap.sh
#

global FILE_REGISTRY_HOST_LEVEL_PATH "[default]='/opt/cwt-registry' [help]='Specifies where the files used as key/value store backend should be written. Important note : when hosting multiple CWT projects and/or project instances on the same host, if this value differs, the host-level values won’t be shared (which defeats their purpose).'"
