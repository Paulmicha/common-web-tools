#!/usr/bin/env bash

##
# Deploys current application instance.
#
# The "app deploy" action triggers by default the "app update" action on given
# remote instance.
#
# @see cwt/app/update.sh
#
# @example
#   # Deploy target defaults to the 'prod' remote instance.
#   make app-deploy
#   # Or :
#   cwt/extensions/remote_cwt/app/deploy.sh
#
#   # Deploy to the 'dev' remote instance.
#   make app-deploy 'dev'
#   # Or :
#   cwt/extensions/remote_cwt/app/deploy.sh 'dev'
#

p_remote_id="$1"

if [[ -z "$p_remote_id" ]]; then
  p_remote_id='prod'
fi

u_remote_check_id "$remote_id"

cwt/extensions/remote_cwt/remote/exec.sh "$p_remote_id" \
  'cwt/app/update.sh'
