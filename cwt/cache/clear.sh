#!/usr/bin/env bash

##
# Clears CWT cache.
#
# @see cwt/bootstrap.sh
# @see cwt/utilities/cwt.sh
# @see cwt/utilities/hook.sh
#
# @example
#   make cache-clear
#   # Or :
#   cwt/cache/clear.sh
#

if [[ -d scripts/cwt/local/cache ]]; then
  rm -rf scripts/cwt/local/cache
fi
