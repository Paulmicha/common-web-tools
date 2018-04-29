#!/usr/bin/env bash

##
# CWT core global env vars.
#
# This file (and every others named like it in CWT extensions and in the CWT
# customization dir) is used during "instance init" to generate a single script :
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
# @see cwt/env/current/global.vars.sh
# @see cwt/instance/instance.inc.sh
# @see cwt/utilities/global.sh
# @see cwt/bootstrap.sh
#

global PROJECT_STACK
global PROJECT_DOCROOT "[default]=$PWD"
global APP_DOCROOT "[default]=$PROJECT_DOCROOT/web"
global INSTANCE_TYPE "[default]=dev"
global INSTANCE_DOMAIN "[default]='$(u_get_instance_domain)'"
global INSTANCE_ALIAS

# This allows supporting multi-repo projects, i.e. 1 repo for the app + 1 for
# the "dev stack" :
# - Use CWT_MODE='monolithic' for single-repo projects.
# - Use CWT_MODE='separate' for multi-repo projects (mandatory app Git details).
# TODO support any other combination of any number of repos ?
global CWT_MODE "[default]=separate"
global APP_GIT_ORIGIN "[if-CWT_MODE]=separate"
global APP_GIT_WORK_TREE "[if-CWT_MODE]=separate [default]=$APP_DOCROOT"

# These values are used to generate lookup paths in hooks (events), overrides
# and/or complements.
# @see cwt/custom/README.md
global HOST_TYPE "[default]=local"
global HOST_OS "[default]='$(u_host_get_os)'"
global PROVISION_USING "[default]=docker-compose"
global DEPLOY_USING "[default]=git"

# TODO remove or make opt-in.
global REG_BACKEND "[default]=file"
# TODO else consider using a separate store for secrets, see cwt/env/README.md.
# global SECRETS_BACKEND

# This path indicates where extensions, overrides and complements are to be found.
# That folder should contain current project's private (or "vendor") includes
# used to generate lookup paths in hooks (events), overrides and/or complements.
global CWT_CUSTOM_DIR "[default]=cwt/custom"
