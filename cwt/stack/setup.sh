#!/bin/bash

##
# Setup local instance (Debian 8 LAMP version).
#
# Run as root or sudo.
# [wip] TODO adjustments per env type.
#
# Usage :
# $ . cwt/stack/setup.sh
#

. cwt/env/load.sh

. cwt/git/apply_config.sh
. cwt/app/drupal_setup.sh
. cwt/stack/lamp_deb/cron_drupal_setup.sh

# Domain setup :
# - setup Apache VHost
# - setup (once) certbot auto-renewal cron task for HTTPS / @todo for publicly accessible instances only.
. cwt/stack/lamp_deb/vhost_create.sh $INSTANCE_DOMAIN $INSTANCE_ALIAS
. cwt/stack/lamp_deb/cron_apache_https_setup.sh
