#!/usr/bin/env bash

##
# Global (env) vars for the 'drush' CWT extension.
#
# This file is used during "instance init" to generate the global environment
# variables specific to current project instance.
#
# @see u_instance_init() in cwt/instance/instance.inc.sh
# @see cwt/utilities/global.sh
# @see cwt/bootstrap.sh
#

global DRUSH_DB_DRIVER_FALLBACK "[default]=mysql [help]='Drush being sometimes used as a DB_DRIVER, some DB operations may need to be forwarded to another extension (more low-level) ; the value of this global must be the fallback DB_DRIVER (e.g. mysql or pgsql).'"

global DRUSH_DEFAULT_URI "[default]='$SITE_DOMAIN' [help]='Some commands may need to output absolute URLs, like drush uli, and sometimes the domain cannot be generated properly without passing it as the --uri argument. So this var contains the default uri to use. For multi-site Drupal setups, see the extension : drupalwt'"
