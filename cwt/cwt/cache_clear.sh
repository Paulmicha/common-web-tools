#!/usr/bin/env bash

##
# Clears the local CWT cache.
#
# @see cwt/bootstrap.sh
# @see cwt/utilities/cwt.sh
# @see cwt/utilities/hook.sh
#
# @example
#   make cc
#   # Or :
#   cwt/cwt/cache_clear.sh
#

if [[ -d data/cwt/cache ]]; then
  rm -rf data/cwt/cache
  echo "Cleared local data/cwt/cache dir."
fi
