#!/usr/bin/env bash

##
# Implements hook -s 'instance' -p 'pre' -a 'rebuild' -v 'PROVISION_USING HOST_TYPE INSTANCE_TYPE'
#
# Rewrites locally generated CWT files - e.g. docker-compose.yml, settings
# files, etc. based on the values previously set for the following global global
# env. vars :
# - $INSTANCE_TYPE
# - $INSTANCE_DOMAIN
# - $HOST_TYPE
# - $PROVISION_USING
#
# @see cwt/instance/reinit.sh
# @see cwt/instance/rebuild.sh
#

env -i \
  CWT_SSH_PUBKEY="$CWT_SSH_PUBKEY" \
  CWT_DB_ID="$CWT_DB_ID" \
  HOME="$HOME" LC_CTYPE="${LC_ALL:-${LC_CTYPE:-$LANG}}" PATH="$PATH" USER="$USER" \
  cwt/instance/reinit.sh
