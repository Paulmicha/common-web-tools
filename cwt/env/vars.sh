#!/bin/bash

##
# Env settings model file.
#
# This file is dynamically included during stack init.
# @see cwt/stack/init.sh
# @see cwt/utilities/stack.sh
# @see cwt/utilities/env.sh
#
# Matching rules and syntax are explained in documentation :
# @see cwt/env/README.md
#

define PROJECT_STACK
define PROJECT_DOCROOT "[default]=$PWD"
define REG_BACKEND "[default]=file"
# TODO consider using a separate store for secrets, see cwt/env/README.md.
# define SECRETS_BACKEND

define PROVISION_USING "[default]=docker-compose"
define HOST_OS "[default]='$(u_host_get_os)'"
define HOST_TYPE "[default]=local"

define APP_DOCROOT "[default]=\$PROJECT_DOCROOT/web"
define INSTANCE_TYPE "[default]=dev"
define INSTANCE_DOMAIN "[default]='$(u_get_instance_domain)'"
define INSTANCE_ALIAS

# TODO provide different examples.
define DEPLOY_USING "[default]=git"

# TODO provide tests / CI examples.
