#!/usr/bin/env bash

##
# Installs a new project using 'drush site-install'.
#
# @param 1 String : the site name (human readable).
# @param 2 String : the "distro" name.
# @param 3 [optional] String : the site e-mail.
#   Defaults to "site@${INSTANCE_DOMAIN}"
# @param 4 [optional] String : the admin account e-mail.
#   Defaults to "admin@${INSTANCE_DOMAIN}"
# @param 5 [optional] String : the admin account name (login).
#   Defaults to 'admin'
# @param 6 [optional] String : the admin account password.
#   Defaults to 'admin'
#
# @example
#   make new-site-install "My project" 'thunder'
#   # Or :
#   cwt/extensions/drupalwt/new/site-install.sh "My project" 'thunder'
#

. cwt/bootstrap.sh

# Prerequisites checks.
if [[ -z "$1" ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO: argument 1 (the human-readable site name) is required." >&2
  echo "-> Aborting (1)." >&2
  echo >&2
  exit 1
fi
if [[ -z "$2" ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO: argument 2 (the 'distro' machine name) is required." >&2
  echo "-> Aborting (2)." >&2
  echo >&2
  exit 2
fi

# Default value for $3 : site e-mail.
site_mail="site@${INSTANCE_DOMAIN}"
if [[ -n "$3" ]]; then
  site_mail="$3"
fi

# Default value for $4 : admin account e-mail.
account_mail="admin@${INSTANCE_DOMAIN}"
if [[ -n "$4" ]]; then
  account_mail="$4"
fi

# Default value for $5 : admin account name (login).
account_name="admin"
if [[ -n "$5" ]]; then
  account_name="$5"
fi

# Default value for $6 : admin account pass.
account_pass='admin'
if [[ -n "$6" ]]; then
  account_pass="$6"
fi

echo "Installing a new project using 'drush site-install' ..."

drush site-install "$1" --verbose --yes \
  --db-url="$DB_DRIVER://$DB_USER:$DB_PASS@$DB_HOST:$DB_PORT/$DB_NAME" \
  --site-mail="$site_mail" \
  --account-mail="$account_mail" \
  --site-name="$2" \
  --account-name="$account_name" \
  --account-pass="$account_pass"

echo "Installing a new project using 'drush site-install' : done."
