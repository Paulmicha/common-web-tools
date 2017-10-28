#!/bin/bash

##
# [wip] Writes current local instance env settings.
#
# This script copies files from the "dist" dir into "current", while replacing
# their placeholders with the values generated by the stack init script.
# @see cwt/stack/init.sh
#
# Some settings may be applicable only for some type of project stack, provision
# method, or any combination of stack init script arguments.
# Conditional generation of corresponding env settings uses naming convention
# and folder structure, as described in the example below.
#
# Given the following value for the '-s' or '--stack' arg: "drupal-7",
# and for the '-p' or '--provision' arg: "scripts", this script will attempt to
# copy the contents of all the following files (if they exist), append it to the
# file storing settings of the current local instance, cwt/env/current/.app.vars.sh :
# - cwt/env/dist/drupal/app.vars.sh.dist
# - cwt/env/dist/drupal/scripts_provision.vars.sh.dist
# - cwt/env/dist/drupal/7/app.vars.sh.dist
# - cwt/env/dist/drupal/7/scripts_provision.vars.sh.dist
#
# Then it proceeds to replace all placeholders from the dist files with values
# from variables populated in stack init, using the following convention :
# __replace_this_DB_NAME_value__ -> $P_DB_NAME
#
# Prerequisites :
# Variables populated with the values generated by the stack init script.
# @see cwt/stack/init.sh
#
# Usage :
# . cwt/env/write.sh
#

# TODO remove previously hardcoded implementation below.

# Check params.
if [[ -z "${1}" ]]; then
  echo ""
  echo "ERROR : argument 'instance type' is required."
  echo "Example : \$ . cwt/env/write.sh live myproject.com"
  echo "(allowed instance types are 'dev', 'test', or 'live')"
  echo ""
  return
else
  echo ""
  echo "Instance type is '${1}'."
fi

if [[ -z "${2}" ]]; then
  echo ""
  echo "ERROR : argument 'domain' is required."
  echo "Example : \$ . cwt/env/write.sh live myproject.com"
  echo "(replace the 2nd argument with domain, e.g. myproject.com)"
  echo ""
  return
else
  echo "Domain is '${2}'."
fi

# Copy env files models.
cp -f env/.env.dist .env
cp -f env/.app.env.dist .app.env

# Replace custom values placeholders from models :
# First, in globals (system-related).
sed -e "s,__replace_this_env_value__,${1},g" -i .env
sed -e "s,__replace_this_domain_value__,${2},g" -i .env
if [[ ! -z "${3}" ]]; then
  echo "Domain alias is '${3}'."
  sed -e "s,INSTANCE_ALIAS='',INSTANCE_ALIAS='${3}',g" -i .env
fi
# Then, in app-related env. vars.
# Note : DB root credentials as implemented by default in model (.app.env.dist)
# require cwt/stack/lamp_deb/install.sh
. cwt/db/get_credentials.sh
sed -e "s,__replace_this_db_name_value__,${DB_NAME},g" -i .app.env
sed -e "s,__replace_this_db_username_value__,${DB_USERNAME},g" -i .app.env
sed -e "s,__replace_this_db_password_value__,${DB_PASSWORD},g" -i .app.env

# Finally, deal with additional instance-type-specific env.
CHOSEN_ENV_MODEL="env/${1}.env.dist"
if [ -f $CHOSEN_ENV_MODEL ]; then
  echo "File $CHOSEN_ENV_MODEL exists -> adding it as well."
  cp -f $CHOSEN_ENV_MODEL ".this.env"
fi

echo ""
echo "Over."
echo ""
