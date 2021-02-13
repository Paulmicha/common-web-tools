#!/usr/bin/env bash

##
# Implements hook -s 'app' -a 'install' -v 'PROVISION_USING INSTANCE_TYPE'
#
# @see cwt/app/install.sh
# @see cwt/instance/setup.sh
#
# This file is dynamically included when the "hook" is triggered.
#
# Debug lookup paths (make sure this file gets picked up) :
# $ make hook-debug s:app a:install v:PROVISION_USING INSTANCE_TYPE
#
# @example
#   make app-install
#   # Or :
#   cwt/app/install.sh
#

case "$D4D_USE_SOLR" in 'yes')
  # @see cwt/extensions/drupalwt_d4d/cwt/alias.docker-compose.hook.sh
  # See https://github.com/wodby/solr/blob/master/bin/init_solr
  init_solr &> /dev/null

  if [[ $? -ne 0 ]]; then
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO: failed to create the 'default' Solr core." >&2
    echo >&2
  else
    echo "The 'default' Solr core has been created."
  fi
esac
