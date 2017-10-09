#!/bin/bash

##
# LAMP server Apache VHost creation.
#
# Run as root or sudo.
#
# Usage (replace example domain + optional alias passed as arguments) :
# $ . scripts/stack/lamp_deb/vhost_create.sh
# $ . scripts/stack/lamp_deb/vhost_create.sh the-domain.com
# $ . scripts/stack/lamp_deb/vhost_create.sh the-domain.com www.the-domain.com
#

. scripts/env/load.sh

# Fall back to env $INSTANCE_DOMAIN when no 1st argument.
if [[ -z "${1}" ]]; then
  # echo "ERROR : domain (1st argument) is required."
  # echo "Example : \$ . scripts/stack/lamp_deb/vhost_create.sh the-domain.com"
  # return
  DOMAIN=$INSTANCE_DOMAIN
else
  DOMAIN="${1}"
fi

DOCROOT="$INSTALL_PATH/web"

# Optional alias as 2nd argument.
ALIAS=''
if [[ ! -z ${2} ]]; then
  ALIAS="ServerAlias ${2}"
  echo "Optional $ALIAS is detected."
fi

echo "Writing /etc/apache2/sites-available/${DOMAIN}.conf ..."

cat > /etc/apache2/sites-available/${DOMAIN}.conf <<EOF
<VirtualHost *:80>

    ServerName $DOMAIN
    $ALIAS
    ServerAdmin webmaster@localhost

    DocumentRoot $DOCROOT

    <Directory $DOCROOT>
        Options Indexes FollowSymLinks MultiViews
        AllowOverride All
        Order allow,deny
        allow from all
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/$DOMAIN.error.log
    LogLevel warn
    CustomLog \${APACHE_LOG_DIR}/$DOMAIN.access.log combined

</VirtualHost>
EOF

echo "Enabling $DOMAIN ..."
a2ensite $DOMAIN
echo "Reloading Apache config ..."
service apache2 reload
echo "Done."
