#!/usr/bin/env bash

##
# Deploy stack update to remote instance.
#
# @example
#   # Deploy target defaults to the 'prod' remote instance.
#   make stack-deploy
#   # Or :
#   cwt/extensions/remote/stack/deploy.sh
#
#   # Deploy to the 'dev' remote instance.
#   make stack-deploy 'dev'
#   # Or :
#   cwt/extensions/remote/stack/deploy.sh 'dev'
#

p_remote_id="$1"

if [[ -z "$p_remote_id" ]]; then
  p_remote_id='prod'
fi

# TODO (wip) Detect containers that may need to be rebuilt ?
# Turn this into an abstract entry point ?
cwt/extensions/remote/remote/exec.sh "$p_remote_id" \
  'git pull && cwt/instance/reinit.sh && cwt/instance/restart.sh'
