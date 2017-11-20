#!/bin/bash

##
# Setup host-level dependencies.
#
# Run as root or sudo.
#
# Usage :
# $ . cwt/stack/setup.sh
#

. cwt/env/load.sh

. cwt/git/apply_config.sh

# . cwt/app/drupal_setup.sh
# . cwt/stack/lamp_deb/cron_drupal_setup.sh
# . cwt/stack/lamp_deb/vhost_create.sh $INSTANCE_DOMAIN $INSTANCE_ALIAS
# . cwt/stack/lamp_deb/cron_apache_https_setup.sh


# Allow custom complements for this script.
u_autoload_get_complement "$BASH_SOURCE"
