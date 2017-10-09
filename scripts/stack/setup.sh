#!/bin/bash

##
# Setup local instance (Debian 8 LAMP version).
#
# Run as root or sudo.
# [wip] TODO adjustments per env type.
#
# Usage :
# $ . scripts/stack/setup.sh
#

. scripts/env/load.sh

. scripts/git/apply_config.sh
. scripts/app/drupal_setup.sh
. scripts/stack/lamp_deb/cron_drupal_setup.sh

# Domain setup :
# - setup Apache VHost
# - setup (once) certbot auto-renewal cron task for HTTPS / @todo for publicly accessible instances only.
. scripts/stack/lamp_deb/vhost_create.sh $INSTANCE_DOMAIN $INSTANCE_ALIAS
. scripts/stack/lamp_deb/cron_apache_https_setup.sh
