#!/usr/bin/env bash

##
# Restart containers.
#
# This script is meant to be called by another script. Unless we know what we're
# doing, we shouldn't have to call it directly.
# @see cwt/stack/restart.sh
#

# Allow custom override for this script.
eval `u_autoload_override "$BASH_SOURCE"`


echo "Restart docker service..."
service docker restart


# Allow custom complements for this script.
u_autoload_get_complement "$BASH_SOURCE"
