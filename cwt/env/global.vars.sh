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

# 1. Mandatory CWT "core" globals.
global PROJECT_DOCROOT "[default]='$PWD' [help]='Absolute path to project instance. All scripts using CWT *must* be run from this dir. No trailing slash.'"

global STACK_VERSION "[default]=v1 [help]='A string that is used for example when we upgrade one or more services (or the whole stack). See cwt/extensions/docker-compose/stack/switch.sh'"

global INSTANCE_TYPE "[default]=dev [help]='E.g. dev, stage, prod... It is used as the default variant for hook calls that do not pass any in args.'"

global PROVISION_USING "[default]=docker-compose [help]='Generic differenciator used by many hooks. It does not have to be explicitly named after the host provisioning tool used. It could be any distinction used as variants in hook implementations.'"

global HOST_TYPE "[default]=local [help]='Idem. E.g. local, remote...'"

global HOST_OS "$(u_host_os)"

# [optional] Provide additional custom makefile includes, and short subjects
# or actions replacements used for generating Makefile task names.
# @see u_make_generate()
# @see u_make_task_name()
# @see Makefile
global CWT_MAKE_INC "[append]='$(u_cwt_extensions_get_makefiles)'"
global CWT_MAKE_TASKS_SHORTER "[append]='registry/reg lookup-path/lp'"

# 2. CWT "apps" (or components) enforce a naming convention for dynamically
# generated globals var names. Space-separated list. Defaults to "site".
# @see u_instance_init() in cwt/instance/instance.inc.sh
global CWT_APPS "[default]='site' [help]='CWT apps allow for example to provide as many compose definitions, domains, etc. as we need. Each app may have its own git repo, its own database(s), etc.'"


# TODO [refacto] ex. CWT_COMPONENTS='site api log proxy'
# -> need to provide the following global vars e.g. via /env.yml :
# TODO [evol] provide defaults to only require specifying overrides in /env.yml
#   - SITE_DOCROOT='site'
#   - SITE_DOCROOT_C='/var/www/html'
#   - SITE_DOMAIN='my-project-site.localhost'
#   - SITE_SERVER_DOCROOT='site/web'
#   - SITE_SERVER_DOCROOT_C='/var/www/html/web'
#   - SITE_SERVICES='cache:varnish front:apache app:drupal db:drush cache:redis index:solr db-dev-tool:adminer'
#   - SITE_FRONT_DOMAIN='my-project-site.localhost:82'
#   - SITE_VARNISH_DOMAIN=$SITE_DOMAIN

# TODO [refacto] wip: instead of e.g. :
#   SITE_SERVICES='cache:varnish front:apache ...'
# we could use :
#   SITE_SERVICES='varnish apache ...'
#   SITE_VARNISH_SERVICE_PRESET='cache'
#   SITE_FRONT_SERVICE_PRESET='front'
#   ...

# TODO [refacto] wip: maybe not worth implementing templates of global vars,
# just comment / explain in e.g. /SPECIMEN.env.yml + provide basic mandatory
# checks on dynamic global var names.

# TODO [refacto] wip: and for mandatory global vars that can have a default
# value automatically generated, use the ':' as separator. E.g. :
# mandatory_globals+=('{{ APP }}_{{ SERVICE }}_DB_ID:{{ APP }}')
# mandatory_globals+=('{{ APP }}_{{ SERVICE }}_DB_DRIVER:mysql')
# @see cwt/presets/db/list_mandatory_globals.hook.tpl.sh

# TODO [refacto] wip: CWT_DB_IDS : allow multiple databases per component.
# For now, provided on an opt-in basis like :
# SITE_SERVICES='mysql'
# SITE_MYSQL_SERVICE_PRESET='db'
# SITE_MYSQL_DB_ID='site' # -> default to {{ APP }} + to be automatically
# added to CWT_DB_IDS

# TODO implement default dynamic globals based on CWT_APPS.
# [optional] Set these values for applications having their own separate repo.
# @see cwt/git/init.hook.sh
global APP_GIT_ORIGIN "[help]='Optional. Ex: git@my-git-origin.org:my-git-account/cwt.git. Allows projects to have their own separate repo.'"
global APP_GIT_INIT_CLONE "[ifnot-APP_GIT_ORIGIN]='' [default]=yes [help]='(y/n) Specify if the APP_GIT_ORIGIN repo should automatically be cloned (once) during \"instance init\".'"
global APP_GIT_INIT_HOOK "[ifnot-APP_GIT_ORIGIN]='' [default]=no [help]='(y/n) Specify if some Git hooks should automatically trigger corresponding CWT hooks.
 WARNING : will overwrite existing git hook scripts during instance init.'"
