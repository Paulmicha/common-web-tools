#!/usr/bin/env bash

##
# Detect software profile and store SOFTWARE_VARIANT in the instance registry.
#
# @example
#   make software-discover
#   # Or :
#   cwt/extensions/software/software/discover.sh
#

. cwt/bootstrap.sh

p_variant='default'

# Optional hostname-based profiles (extend as needed).
case "$(hostname -s 2>/dev/null || hostname)" in
  *-laptop|laptop-*)
    p_variant='laptop'
    ;;
  *-desktop|desktop-*)
    p_variant='desktop'
    ;;
esac

u_instance_registry_set 'software_variant' "$p_variant"

echo "software_variant = '$p_variant'"
echo "Over."
