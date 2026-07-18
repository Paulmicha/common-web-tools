#!/usr/bin/env bash

##
# Global (env) vars for the 'entity' core CWT extension.
#
# This file is used during "instance init" to generate the global environment
# variables specific to current project instance.
#
# @see u_instance_init() in cwt/instance/instance.inc.sh
# @see cwt/utilities/global.sh
# @see cwt/bootstrap.sh
#

global CWT_SYNONYMS "[append]='entity-create/entity-add'"
global CWT_SYNONYMS "[append]='entity-delete/entity-remove'"
