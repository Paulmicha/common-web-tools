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
ENV_VARS['PROJECT_STACK.group']="$group"
ENV_VARS['PROJECT_DOCROOT.group']="$group"
ENV_VARS['PROVISION_USING.group']="$group"
ENV_VARS['REG_BACKEND.group']="$group"
# TODO consider using a separate store for secrets, see cwt/env/README.md.
# ENV_VARS['SECRETS_BACKEND.group']="$group"

group='App instance settings'
ENV_VARS['APP_DOCROOT.group']="$group"
ENV_VARS['INSTANCE_TYPE.group']="$group"
ENV_VARS['INSTANCE_DOMAIN.group']="$group"
ENV_VARS['INSTANCE_ALIAS.group']="$group"

group='Deployment settings'
ENV_VARS['DEPLOY_USING.group']="$group"
