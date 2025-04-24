#!/usr/bin/env bash

##
# Switches current project instance type.
#
# @param 1 String : the new instance type.
#
# @example
#   make switch-type 'dev'
#   # Or :
#   cwt/instance/switch_type.sh 'dev'
#

# Force the new instance type value alone.
INSTANCE_TYPE="$1"

# Can't have read-only variables here, so we need to extract just the
# variables we need.
# TODO support all globals for reinits ? For ex. as in :
# @see u_traefik_generate_acme_conf() in cwt/extensions/remote_traefik/remote_traefik.inc.sh
# -> here, we could just pass a custom option that would instruct the
# u_instance_init() function to dynamically get all existing values ?
if [[ -f '.env' ]]; then
  while IFS= read -r line _; do
    case "$line" in
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
  done < '.env'
fi

# Remove all previously initialized values.
. cwt/instance/uninit.sh

# TODO [wip] refactoring : check what we really need to keep.
# @see cwt/instance/reinit.sh
# Wipe out env vars to avoid pile-ups for 'append' type globals during reinit.
# See https://unix.stackexchange.com/a/49057
# Except individual public key path for CWT remote instances operations.
# @see scripts/cwt/extend/remote/post_init.hook.sh
# Also except CWT_DB_ID for the db extension.
# @see u_db_set() in cwt/extensions/db/db.inc.sh
# Also except common shell env vars some programs use.
env -i \
  CWT_SSH_PUBKEY="$CWT_SSH_PUBKEY" \
  CWT_APPS="$CWT_APPS" \
  CWT_DB_ID="$CWT_DB_ID" \
  HOME="$HOME" LC_CTYPE="${LC_ALL:-${LC_CTYPE:-$LANG}}" PATH="$PATH" USER="$USER" \
  cwt/instance/init.sh \
    -t "$INSTANCE_TYPE" \
    -h "$HOST_TYPE" \
    -p "$PROVISION_USING" \
    -y
