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

# Start by removing all previously initialized values.
. cwt/instance/uninit.sh

# Force the new instance type value alone.
INSTANCE_TYPE="$1"

# Then use the same approach as in the "reinit" action.
# @see cwt/instance/reinit.sh
if [[ -f '.env' ]]; then
  while IFS= read -r line _; do
    case "$line" in
      'INSTANCE_DOMAIN='*)
        eval "$line"
        ;;
      'DC_NS='*)
        eval "$line"
        ;;
      'HOST_TYPE='*)
        eval "$line"
        ;;
      'PROVISION_USING='*)
        eval "$line"
        ;;
    esac
  done < '.env'
fi

env -i \
  CWT_SSH_PUBKEY="$CWT_SSH_PUBKEY" \
  CWT_DB_ID="$CWT_DB_ID" \
  HOME="$HOME" LC_CTYPE="${LC_ALL:-${LC_CTYPE:-$LANG}}" PATH="$PATH" USER="$USER" \
  . cwt/instance/init.sh \
    -t "$INSTANCE_TYPE" \
    -d "$INSTANCE_DOMAIN" \
    -c "$DC_NS" \
    -h "$HOST_TYPE" \
    -p "$PROVISION_USING" \
    -y
