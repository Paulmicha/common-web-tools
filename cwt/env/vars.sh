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

group='Stack (host-level) settings'
u_env_var_add PROJECT_STACK "[group]='$group'"
u_env_var_add PROJECT_DOCROOT "[group]='$group' [default]='$(pwd)'"
u_env_var_add PROVISION_USING "[group]='$group' [default]='docker-compose-2'"
u_env_var_add REG_BACKEND "[group]='$group' [default]='file'"
# TODO consider using a separate store for secrets, see cwt/env/README.md.
# u_env_var_add SECRETS_BACKEND "[group]='$group'"

group='App instance settings'
u_env_var_add APP_DOCROOT "[group]='$group'"
u_env_var_add INSTANCE_TYPE "[group]='$group'"
u_env_var_add INSTANCE_DOMAIN "[group]='$group'"
u_env_var_add INSTANCE_ALIAS "[group]='$group'"

group='Deployment settings'
u_env_var_add DEPLOY_USING "[group]='$group'"
