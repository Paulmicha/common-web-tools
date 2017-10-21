#!/bin/bash

##
# Loads current environment vars and aliases.
#
# This script is idempotent (can be imported many times). Note: combined scripts
# may result in sourcing this file many times over, because for simplicity there
# is no verification preventing this from happening.
#
# Usage :
# . cwt/env/load.sh
#

if [ ! -f .env ]; then
  echo "ERROR : .env file does not exist. Run the env/write script first."
  echo "Example : \$ . cwt/env/write.sh live"
  echo "(replace the first argument with namespace, e.g. dev, test, live)"
  return
fi

. .env
. .app.env
. .git.env

# Load env-type-specific vars (if exists).
if [ -f ".$INSTANCE_TYPE.env" ]; then
  echo ".$INSTANCE_TYPE.env exists and is loaded."
  . .$INSTANCE_TYPE.env
fi

# Load project's remote host.
# @evol manage several hosts (per instance type ?)
if [ -f ".remote_hosts.env" ]; then
  . .remote_hosts.env
fi

# Load global bash utils and aliases.
. cwt/bash_utils.sh
. cwt/env/registry.sh
. cwt/aliases.sh
