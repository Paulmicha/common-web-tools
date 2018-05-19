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
# Unless the "instance init" command is set to bypass prompts, most calls to
# global() will prompt for confirming or replacing default values or for simply
# entering a value if no default is declared. The only exceptions are global
# declarations explicitly providing a value.
#
# @see cwt/env/current/global.vars.sh
# @see cwt/instance/instance.inc.sh
# @see cwt/utilities/global.sh
# @see cwt/bootstrap.sh
#

global PROJECT_DOCROOT "[default]=$PWD"
global APP_DOCROOT "[default]=$PROJECT_DOCROOT/web"

# [optional] Set these values for applications having their own separate repo
# in order to benefit from the automatic instanciation and Git hooks integration
# features provided by CWT core by default (overridable).
# @see cwt/git/init.hook.sh
global APP_GIT_ORIGIN
global APP_GIT_WORK_TREE "[default]=$APP_DOCROOT"

global INSTANCE_TYPE "[default]=dev"
global INSTANCE_DOMAIN "[default]='$(u_instance_domain)'"
global PROVISION_USING "[default]=docker-compose"
global HOST_TYPE "[default]=local"
global HOST_OS "$(u_host_os)"

# Path to custom scripts ~ commonly automated processes. CWT will also use this
# path to look for overrides and complements.
# @see u_autoload_override()
# @see u_autoload_get_complement()
global PROJECT_SCRIPTS "[default]=scripts"

# [optional] Provide additional custom makefile includes, and short subjects
# or actions replacements used for generating Makefile task names.
# @see u_instance_write_mk()
# @see u_instance_task_name()
# @see Makefile
global CWT_MAKE_INC "[append]='$PROJECT_SCRIPTS/make.mk'"
global CWT_MAKE_TASKS_SHORTER "[append]='registry/reg lookup-path/lp'"
