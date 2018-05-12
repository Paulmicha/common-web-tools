#!/usr/bin/env bash

##
# Global (env) vars for the 'docker-compose' CWT extension.
#
# This file is automatically loaded during "instance init" to generate a single
# script :
#
# cwt/env/current/global.vars.sh
#
# That script file will contain declarations for every global variables found in
# this project instance as readonly. It is git-ignored and loaded on every
# bootstrap - if it exists, that is if "instance init" was already launched once
# in current project instance.
#
# Unless the "instance init" command is set to bypass prompts, every call to
# global() will prompt for confirming or replacing default values or for simply
# entering a value if no default is declared.
#
# @see cwt/instance/instance.inc.sh
# @see cwt/utilities/global.sh
# @see cwt/bootstrap.sh
#

# Specifies where the generated (& to be git-ignored) docker-compose.yml file
# will be (over)written.
# @see u_stack_template()
global DC_YML "[default]='$PROJECT_DOCROOT/docker-compose.yml'"

# Determines which docker-compose.yml "template" will be used for current project
# instance.
# @see u_stack_template()
global DC_YML_VARIANTS "[default]='INSTANCE_TYPE HOST_TYPE'"
