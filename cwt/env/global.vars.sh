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

global PROJECT_DOCROOT "[default]=$PWD [help]='Absolute path to project instance. All scripts MUST be run from this dir. No trailing slash.'"
global APP_DOCROOT "[default]=$PROJECT_DOCROOT/web [help]='The application may have its \"entry point\" in a different dir than PROJECT_DOCROOT. It could be a folder accessible from the web.'"

# [optional] Set these values for applications having their own separate repo
# in order to benefit from the automatic instanciation and Git hooks integration
# features provided by CWT core by default (overridable).
# @see cwt/git/init.hook.sh
global APP_GIT_ORIGIN "[help]='Optional. Ex: git@my-git-origin.org:my-git-account/cwt.git. Allows projects to have their own separate repo. If set, then by default \"instance init\" will clone that repo (once) and a default selection of Git hooks will be overwritten to trigger CWT hooks.'"
global APP_GIT_WORK_TREE "[ifnot-APP_GIT_ORIGIN]='' [default]=$APP_DOCROOT [help]='Some applications might contain APP_DOCROOT in their versionned sources. This global is the path of the git work tree (if different).'"

global INSTANCE_TYPE "[default]=dev [help]='E.g. dev, stage, prod... It is used as the default variant for hook triggers not defining any.'"
global INSTANCE_DOMAIN "[default]='$(u_instance_domain)' [help]='This value is used to identify different project instances and MUST be unique per host.'"
global PROVISION_USING "[default]=docker-compose [help]='Generic differenciator used by many hooks. It does not have to be explicitly named after the host provisioning tool used. It could be any distinction allowing a wider variety of implementations for the same project (~ additional isolation).'"
global HOST_TYPE "[default]=local [help]='Idem. E.g. local, remote...'"
global HOST_OS "$(u_host_os)"

# Path to custom scripts ~ commonly automated processes. CWT will also use this
# path to look for overrides and complements.
# @see u_autoload_override()
# @see u_autoload_get_complement()
global PROJECT_SCRIPTS "[default]=scripts [help]='Path to custom scripts ~ commonly automated processes. CWT will also use this path to look for overrides and complements (alteration mecanisms).'"

# [optional] Provide additional custom makefile includes, and short subjects
# or actions replacements used for generating Makefile task names.
# @see u_instance_write_mk()
# @see u_instance_task_name()
# @see Makefile
global CWT_MAKE_INC "[append]='$PROJECT_SCRIPTS/make.mk'"
global CWT_MAKE_TASKS_SHORTER "[append]='registry/reg lookup-path/lp'"
