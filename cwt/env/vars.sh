#!/bin/bash

##
# Env (settings) model file.
#
# This file is dynamically included during stack init.
# @see u_env_vars_aggregate()
#
# Matching rules and syntax are explained in documentation :
# @see cwt/env/README.md
#

u_env_var_add PROJECT_STACK
u_env_var_add PROJECT_DOCROOT "[default]=$(pwd)"
u_env_var_add PROVISION_USING "[default]=docker-compose-2"
u_env_var_add REG_BACKEND "[default]=file"
# TODO consider using a separate store for secrets, see cwt/env/README.md.
# u_env_var_add SECRETS_BACKEND

u_env_var_add APP_DOCROOT "[default]=$(pwd)/web"
u_env_var_add INSTANCE_TYPE "[default]=dev"
u_env_var_add INSTANCE_DOMAIN "[default]=$(u_get_instance_domain)"
u_env_var_add INSTANCE_ALIAS

u_env_var_add DEPLOY_USING "[default]=git"
