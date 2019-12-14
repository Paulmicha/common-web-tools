#!/usr/bin/env bash

##
# Installs a new project using 'drush site-install'.
#
# See https://drushcommands.com/drush-9x/site/site:install/
#
# @param 1 [optional] String : the site name (human readable). Defaults to :
#   "Hello world".
# @param 2 [optional] String : A Drupal install profile name. Defaults to
#   'standard' unless an install profile is marked as a distribution. Additional
#   info for the install profile may also be provided with additional arguments.
#   The key is in the form [form name].[parameter name].
# @param 3 [optional] String : the admin account name (login).
#   Defaults to 'admin'.
# @param 4 [optional] String : the admin account password.
#   Defaults to 'admin'.
# @param 5 [optional] String : the admin account e-mail.
#   Defaults to "admin@${INSTANCE_DOMAIN}".
# @param 6 [optional] String : the site e-mail.
#   Defaults to "site@${INSTANCE_DOMAIN}".
#
# @example
#   # By default, this will install a new Drupal site named "Hello world" with
#   # the 'standard' install profile, and the superadmin account credentials
#   # will be : admin / admin.
#   make new-site-install
#   # Or :
#   cwt/extensions/drupalwt/new/site-install.sh
#
#   # To specify a site name + install profile :
#   make new-site-install "My project" 'minimal'
#   # Or :
#   cwt/extensions/drupalwt/new/site-install.sh "My project" 'minimal'
#
#   # To specify superadmin credentials :
#   superadmin_password="$(u_str_random)"
#   echo "Your superadmin login credentials will be : admin / $superadmin_password"
#   make new-site-install "My project" 'minimal' 'admin' "$superadmin_password"
#   # Or :
#   cwt/extensions/drupalwt/new/site-install.sh "My project" 'minimal' 'admin' "$superadmin_password"
#

. cwt/bootstrap.sh

# Default value for $1 : site name.
site_name="Hello world"
if [[ -n "$1" ]]; then
  site_name="$1"
fi

# Default value for $2 : Drupal install profile name.
install_profile='standard'
if [[ -n "$2" ]]; then
  install_profile="$2"
fi

# Default value for $3 : admin account name (login).
account_name="admin"
if [[ -n "$3" ]]; then
  account_name="$3"
fi

# Default value for $4 : admin account pass.
account_pass='admin'
if [[ -n "$4" ]]; then
  account_pass="$4"
fi

# Default value for $5 : admin account e-mail.
account_mail="admin@${INSTANCE_DOMAIN}"
if [[ -n "$5" ]]; then
  account_mail="$5"
fi

# Default value for $6 : site e-mail.
site_mail="site@${INSTANCE_DOMAIN}"
if [[ -n "$6" ]]; then
  site_mail="$6"
fi

echo "Installing a new project using 'drush site-install' ..."

u_db_get_credentials

drush site-install "$install_profile" --verbose --yes \
  --db-url="$DB_DRIVER://$DB_USER:$DB_PASS@$DB_HOST:$DB_PORT/$DB_NAME" \
  --site-name="$site_name" \
  --site-mail="$site_mail" \
  --account-name="$account_name" \
  --account-pass="$account_pass" \
  --account-mail="$account_mail"

if [[ $? -ne 0 ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO: the command 'drush site-install' exited with a non-zero code." >&2
  echo "-> Aborting (1)." >&2
  echo >&2
  exit 1
fi

echo "Installing a new project using 'drush site-install' : done."
