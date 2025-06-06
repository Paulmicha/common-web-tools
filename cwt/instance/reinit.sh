#!/usr/bin/env bash

##
# Reinitializes current project instance without changing existing settings.
#
# TODO [wip] check which vars are really essential to be kept (hardcoded).
#
# Rewrites locally generated CWT files while keeping the values - if previously
# set - for the following global env. vars :
# - $INSTANCE_TYPE
# - $INSTANCE_DOMAIN
# - $STACK_VERSION
# - $HOST_TYPE
# - $PROVISION_USING
# - $CWT_SSH_PUBKEY
#
# @example
#   make reinit
#   # Or :
#   cwt/instance/reinit.sh
#

# Update 2024-06 cache results.
. cwt/instance/cwt_cache_clear.sh

# Can't have read-only variables here, so we need to extract just the
# variables we need.
# TODO support all globals for reinits ? For ex. as in :
# @see u_traefik_generate_acme_conf() in cwt/extensions/remote_traefik/remote_traefik.inc.sh
# -> here, we could just pass a custom option that would instruct the
# u_instance_init() function to dynamically get all existing values ?
if [[ -f '.env' ]]; then
  while IFS= read -r line _; do
    case "$line" in
      'STACK_VERSION='*)
        eval "$line"
        ;;
      'CWT_APPS='*)
        eval "$line"
        ;;
      'INSTANCE_TYPE='*)
        eval "$line"
        ;;
      # 'INSTANCE_DOMAIN='*)
      #   eval "$line"
      #   ;;
      'HOST_TYPE='*)
        eval "$line"
        ;;
      'PROVISION_USING='*)
        eval "$line"
        ;;
      'CWT_SSH_PUBKEY='*)
        eval "$line"
        ;;
    esac

    if [[ -n "$CWT_APPS" ]]; then
      for app in $CWT_APPS; do
        case "$line" in "${app}_DOMAIN="*|"${app}_GIT_ORIGIN="*|"${app}_SERVER_DOCROOT="*)
          eval "$line"
        esac
      done
    fi
  done < '.env'
fi

# Wipe out env vars to avoid pile-ups for 'append' type globals during reinit.
# See https://unix.stackexchange.com/a/49057
# Except individual public key path for CWT remote instances operations.
# @see scripts/cwt/extend/remote/post_init.hook.sh
# Also except CWT_DB_ID for the db extension.
# @see u_db_set() in cwt/extensions/db/db.inc.sh
# Also except common shell env vars some programs use.
env -i \
  CWT_SSH_PUBKEY="$CWT_SSH_PUBKEY" \
  CWT_DB_ID="$CWT_DB_ID" \
  CWT_APPS="$CWT_APPS" \
  HOME="$HOME" LC_CTYPE="${LC_ALL:-${LC_CTYPE:-$LANG}}" PATH="$PATH" USER="$USER" \
  cwt/instance/init.sh \
    -t "$INSTANCE_TYPE" \
    -s "$STACK_VERSION" \
    -h "$HOST_TYPE" \
    -p "$PROVISION_USING" \
    -y

    # -d "$INSTANCE_DOMAIN" \
