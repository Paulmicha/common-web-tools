#!/bin/bash

##
# Apache HTTPS letsencrypt manual setup.
#
# Run as root or sudo.
#
# See :
# https://certbot.eff.org/all-instructions/#debian-8-jessie-apache
# https://www.digitalocean.com/community/tutorials/how-to-secure-apache-with-let-s-encrypt-on-debian-8
#

PKG_OK=$(dpkg-query -W --showformat='${Status}\n' python-certbot-apache|grep "install ok installed")
echo "Checking if python-certbot-apache is installed : $PKG_OK"

if [ "" == "$PKG_OK" ]; then
  echo "python-certbot-apache doesn't appear to be installed."
  echo "Installing now."

  # @todo verify if backports.list are not already present.
  echo 'deb http://ftp.debian.org/debian jessie-backports main' | tee /etc/apt/sources.list.d/backports.list
  apt update

  apt install python-certbot-apache -t jessie-backports -y
fi

# Launch wizard : scans existing VHosts to automatically create missing VHosts
# configuration files for their SSL (HTTPS) counterparts.
# Important note : this will display prompts during setup.
certbot --apache
