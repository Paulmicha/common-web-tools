#!/usr/bin/env bash

##
# CWT remote instance *setup* action.
#
# Starts by running the remote instance *init* action, then :
#   - starts services (if any are implemented),
#   - executes the app install action (if any operations are implemented).
#
# @param 1 String : remote instance ID.
# @param ... all the memaining params are forwarded to cwt/instance/init.sh (but
#   the host type is preset to 'remote')
#
# @example
#   # Sets up a new LAN instance of type 'prod' without interactive terminal
#   # prompts, overriding the host type to 'local' (to avoid being assigned
#   # the 'prod remote' INSTANCE_DOMAIN when we're using the local YAML settings
#   # overrides - i.e. scripts/cwt/override/.env-local.remote.prod.yml):
#   cwt/extensions/remote_cwt/remote/setup.sh 'lan' -t 'prod' -h 'local'
#

u_remote_check_id "$1"

cwt/extensions/remote_cwt/remote/init.sh $@

if [[ $? -ne 0 ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO: remote project initialization failed." >&2
  echo "-> Aborting (1)." >&2
  echo >&2
  exit 1
fi

cwt/extensions/remote_cwt/remote/exec.sh "$1" \
  'cwt/instance/start.sh && cwt/app/install.sh'
