#!/usr/bin/env bash

##
# Clears the local CWT cache.
#
# @see cwt/bootstrap.sh
# @see cwt/utilities/cwt.sh
# @see cwt/utilities/hook.sh
#
# @example
#   make cwt-cache-clear
#   # Or :
#   cwt/instance/cwt_cache_clear.sh
#

if [[ -d scripts/cwt/local/cache ]]; then
  rm -rf scripts/cwt/local/cache
fi
