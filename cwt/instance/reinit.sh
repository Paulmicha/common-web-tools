#!/usr/bin/env bash

##
# Reinitializes current project instance without changing existing settings.
#
# Rewrites locally generated CWT files based on the values initially set for the
# following global env. vars :
# - $INSTANCE_TYPE
# - $INSTANCE_DOMAIN
# - $HOST_TYPE
# - $PROVISION_USING
#
# @example
#   make reinit
#   # Or :
#   cwt/instance/reinit.sh
#

# Wipe out env vars to avoid pile-ups for 'append' type globals during reinit.
# See https://unix.stackexchange.com/a/49057
env -i \
  # Except individual public key path for CWT remote instances operations.
  # @see scripts/cwt/extend/remote/post_init.hook.sh
  CWT_SSH_PUBKEY="$CWT_SSH_PUBKEY" \
  # Also except CWT_DB_ID for the db extension.
  # @see u_db_get_credentials() in cwt/extensions/db/db.inc.sh
  CWT_DB_ID="$CWT_DB_ID" \
  # Also except common shell env vars some programs use.
  HOME="$HOME" LC_CTYPE="${LC_ALL:-${LC_CTYPE:-$LANG}}" PATH="$PATH" USER="$USER" \
  # Now we're good.
  . cwt/instance/init.sh \
    -t "$INSTANCE_TYPE" \
    -d "$INSTANCE_DOMAIN" \
    -h "$HOST_TYPE" \
    -p "$PROVISION_USING" \
    -y
