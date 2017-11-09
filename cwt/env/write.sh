#!/bin/bash

##
# [wip] Writes current local instance env settings.
#
# Usage :
# . cwt/env/write.sh
#

# TODO remove previously hardcoded implementation below.

# Check params.
# if [[ -z "${1}" ]]; then
#   echo ""
#   echo "ERROR : argument 'instance type' is required."
#   echo "Example : \$ . cwt/env/write.sh live myproject.com"
#   echo "(allowed instance types are 'dev', 'test', or 'live')"
#   echo ""
#   return
# else
#   echo ""
#   echo "Instance type is '${1}'."
# fi

# if [[ -z "${2}" ]]; then
#   echo ""
#   echo "ERROR : argument 'domain' is required."
#   echo "Example : \$ . cwt/env/write.sh live myproject.com"
#   echo "(replace the 2nd argument with domain, e.g. myproject.com)"
#   echo ""
#   return
# else
#   echo "Domain is '${2}'."
# fi

# # Copy env files models.
# cp -f env/.env.dist .env
# cp -f env/.app.env.dist .app.env

# # Replace custom values placeholders from models :
# # First, in globals (system-related).
# sed -e "s,__replace_this_env_value__,${1},g" -i .env
# sed -e "s,__replace_this_domain_value__,${2},g" -i .env
# if [[ ! -z "${3}" ]]; then
#   echo "Domain alias is '${3}'."
#   sed -e "s,INSTANCE_ALIAS='',INSTANCE_ALIAS='${3}',g" -i .env
# fi
# # Then, in app-related env. vars.
# # Note : DB root credentials as implemented by default in model (.app.env.dist)
# # require cwt/stack/lamp_deb/install.sh
# . cwt/db/get_credentials.sh
# sed -e "s,__replace_this_db_name_value__,${DB_NAME},g" -i .app.env
# sed -e "s,__replace_this_db_username_value__,${DB_USERNAME},g" -i .app.env
# sed -e "s,__replace_this_db_password_value__,${DB_PASSWORD},g" -i .app.env

# # Finally, deal with additional instance-type-specific env.
# CHOSEN_ENV_MODEL="env/${1}.env.dist"
# if [ -f $CHOSEN_ENV_MODEL ]; then
#   echo "File $CHOSEN_ENV_MODEL exists -> adding it as well."
#   cp -f $CHOSEN_ENV_MODEL ".this.env"
# fi

# echo ""
# echo "Over."
# echo ""
