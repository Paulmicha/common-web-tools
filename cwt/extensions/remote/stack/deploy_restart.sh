#!/usr/bin/env bash

##
# Deploy stack update to remote instance with restart of services.
#
# @example
#   # Deploy target defaults to the 'prod' remote instance.
#   make stack-deploy-restart
#   # Or :
#   cwt/extensions/remote/stack/deploy.sh
#
#   # Deploy to the 'dev' remote instance.
#   make stack-deploy-restart 'dev'
#   # Or :
#   cwt/extensions/remote/stack/deploy_restart.sh 'dev'
#

p_remote_id="$1"

if [[ -z "$p_remote_id" ]]; then
  p_remote_id='prod'
fi

cwt/extensions/remote/remote/exec.sh "$p_remote_id" \
  'git pull && cwt/instance/reinit.sh && cwt/instance/restart.sh'
