#!/usr/bin/env bash

##
# Switches current project stack version.
#
# @see cwt/instance/reinit.sh
# @see cwt/instance/switch_type.sh
#
# @param 1 String : the new stack version.
#
# @example
#   make switch-stack-version 'project-2025'
#   make rebuild
#   # Or :
#   cwt/instance/switch_stack_version.sh 'project-2025'
#   cwt/instance/rebuild.sh
#

# Force the new instance type value alone.
STACK_VERSION="$1"

# Update 2024-06 cache results.
. cwt/cwt/cache_clear.sh

# Can't have read-only variables here, so we need to extract just the
# variables we need.
# TODO support all globals for reinits ? For ex. as in :
# @see u_traefik_generate_acme_conf() in cwt/extensions/remote_traefik/remote_traefik.inc.sh
# -> here, we could just pass a custom option that would instruct the
# u_instance_init() function to dynamically get all existing values ?
if [[ -f '.env' ]]; then
  while IFS= read -r line _; do
    case "$line" in
      'CWT_APPS='*)
        eval "$line"
        ;;
      'INSTANCE_TYPE='*)
        eval "$line"
        ;;
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
