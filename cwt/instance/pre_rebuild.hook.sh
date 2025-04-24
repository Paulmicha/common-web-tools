#!/usr/bin/env bash

##
# Implements hook -s 'instance' -p 'pre' -a 'rebuild' -v 'STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE'
#
# Rewrites locally generated CWT files - e.g. docker-compose.yml, settings
# files, etc. based on the values previously set for the following global global
# env. vars :
# - $CWT_APPS
# - $CWT_DB_ID
# - $INSTANCE_TYPE
# - $HOST_TYPE
# - $PROVISION_USING
#
# TODO check if we can safely remove these hardcoded globals' values to persist.
# In principle yes, as it gets re-initialized using the env.yml files.
# @see u_instance_init() in cwt/instance/instance.inc.sh
#
# @see cwt/instance/reinit.sh
# @see cwt/instance/rebuild.sh
#

env -i \
  CWT_SSH_PUBKEY="$CWT_SSH_PUBKEY" \
  CWT_APPS="$CWT_APPS" \
  CWT_DB_ID="$CWT_DB_ID" \
  HOME="$HOME" LC_CTYPE="${LC_ALL:-${LC_CTYPE:-$LANG}}" PATH="$PATH" USER="$USER" \
  cwt/instance/reinit.sh
