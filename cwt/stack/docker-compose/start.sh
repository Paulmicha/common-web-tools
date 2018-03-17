#!/usr/bin/env bash

##
# Start containers.
#
# This script is meant to be called by another script. Unless we know what we're
# doing, we shouldn't have to call it directly.
# @see cwt/stack/start.sh
#

# Allow custom override for this script.
u_autoload_override "$BASH_SOURCE"
eval "$inc_override_evaled_code"


docker-compose up -d

echo ""
echo "Containers have restarted :"
docker-compose ps


# Allow custom complements for this script.
u_autoload_get_complement "$BASH_SOURCE"
