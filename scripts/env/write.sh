#!/bin/bash

##
# Writes current environment vars.
#
# This script is idempotent (can be run several times without issue).
#
# TODO : decouple from custom Bash scripts to support other provisioning
# implementations (e.g. Ansible or Docker compose).
#
# @param 1 String : the type of instance (ex: 'dev', or : 'test', or: 'live').
# @param 2 String : the domain (ex: 'myproject.com').
# @param 3 [optinal] String : a domain alias (ex: 'www.myproject.com').
#
# @see scripts/stack/lamp_deb/install.sh
# @see scripts/db/get_credentials.sh
#
# Usage examples :
# . scripts/env/write.sh live myproject.com www.myproject.com
# . scripts/env/write.sh dev myproject.lan-0-40.io
# . scripts/env/write.sh test test.myproject.com
#

# Check params.
if [[ -z "${1}" ]]; then
  echo ""
  echo "ERROR : first argument 'instance type' is required."
  echo "Example : \$ . scripts/env/write.sh live myproject.com"
  echo "(allowed instance types are 'dev', 'test', or 'live')"
  echo ""
  return
else
  echo ""
  echo "Instance type is '${1}'."
fi

if [[ -z "${2}" ]]; then
  echo ""
  echo "ERROR : 2nd argument 'domain' is required."
  echo "Example : \$ . scripts/env/write.sh live myproject.com"
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
# require scripts/stack/lamp_deb/install.sh
. scripts/db/get_credentials.sh
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
