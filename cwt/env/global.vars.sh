#!/usr/bin/env bash

##
# CWT core global env vars.
#
# This file (and every others named like it in CWT extensions and in the CWT
# customization dir) is used during "instance init" to generate a single script :
#
# scripts/cwt/local/global.vars.sh
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
# @see cwt/instance/instance.inc.sh
# @see cwt/utilities/global.sh
# @see cwt/bootstrap.sh
#

# Due to differences in some projects directory structures, we now use 3
# variables to cover all cases. Some projects will never need to distinguish
# them, others may only need APP_DOCROOT, and some will also require a different
# path to the folder publicly exposed by the web server.
# This used to be worked around by using a global named APP_GIT_WORK_TREE, but
# for more clarity and flexibility - and to deal more explicitly with somewhat
# convoluted docker-compose path conversion, the SERVER_DOCROOT global was
# finally added (and its Docker volume equivalent SERVER_DOCROOT_C for use from
# containers - see for ex. cwt/extensions/drupalwt/app/global.docker-compose.vars.sh).
global PROJECT_DOCROOT "[default]='$PWD' [help]='Absolute path to project instance. All scripts using CWT *must* be run from this dir. No trailing slash.'"
global APP_DOCROOT "[default]='app' [help]='*Relative* path to the directory containing the application source code. No prefix dot or slash, and no trailing slash.'"
global SERVER_DOCROOT "[default]='$APP_DOCROOT/web' [help]='*Relative* path to the directory usually publicly exposed by web servers (where the app « entry point » would normally reside, e.g. index.php). No prefix dot or slash, and no trailing slash.'"

# [optional] Set these values for applications having their own separate repo.
# @see cwt/git/init.hook.sh
global APP_GIT_ORIGIN "[help]='Optional. Ex: git@my-git-origin.org:my-git-account/cwt.git. Allows projects to have their own separate repo.'"
global APP_GIT_INIT_CLONE "[ifnot-APP_GIT_ORIGIN]='' [default]=yes [help]='(y/n) Specify if the APP_GIT_ORIGIN repo should automatically be cloned (once) during \"instance init\".'"
global APP_GIT_INIT_HOOK "[ifnot-APP_GIT_ORIGIN]='' [default]=no [help]='(y/n) Specify if some Git hooks should automatically trigger corresponding CWT hooks. WARNING : will overwrite existing git hook scripts during instance init.'"

global INSTANCE_TYPE "[default]=dev [help]='E.g. dev, stage, prod... It is used as the default variant for hook calls that do not pass any in args.'"
global INSTANCE_DOMAIN "[default]='$(u_instance_domain)' [help]='This value is used to identify different project instances and MUST be unique. Allowed characters : a-zA-Z0-9-._'"
global PROVISION_USING "[default]=docker-compose [help]='Generic differenciator used by many hooks. It does not have to be explicitly named after the host provisioning tool used. It could be any distinction used as variants in hook implementations.'"
global HOST_TYPE "[default]=local [help]='Idem. E.g. local, remote...'"
global HOST_OS "$(u_host_os)"

# [optional] Provide additional custom makefile includes, and short subjects
# or actions replacements used for generating Makefile task names.
# @see u_instance_write_mk()
# @see u_instance_task_name()
# @see Makefile
global CWT_MAKE_INC "[append]='$(u_cwt_extensions_get_makefiles)'"
global CWT_MAKE_TASKS_SHORTER "[append]='registry/reg lookup-path/lp'"
