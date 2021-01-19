#!/usr/bin/env bash

##
# CWT remote instance switch action.
#
# Remotely executes cwt/instance/switch_type.sh and restarts all stack services.
#
# @param 1 [optional] String : the remote instance ID. Defaults to 'prod'.
# @param 2 [optional] String : the new instance type. Defaults to 'prod'.
#
# @example
#   # Switches the 'prod' remote instance to type 'prod'.
#   make remote-instance-switch
#   # Or :
#   cwt/extensions/remote/remote/instance_switch.sh
#
#   # Switches the 'stage' remote instance to type 'prod'.
#   make remote-instance-switch 'stage'
#   # Or :
#   cwt/extensions/remote/remote/instance_switch.sh 'stage'
#
#   # Switches the 'dev' remote instance to type 'stage'.
#   make remote-instance-switch 'dev' 'stage'
#   # Or :
#   cwt/extensions/remote/remote/instance_switch.sh 'dev' 'stage'
#

. cwt/bootstrap.sh

p_remote_id="$1"
p_new_type="$2"

if [[ -z "$p_remote_id" ]]; then
  p_remote_id='prod'
fi
if [[ -z "$p_new_type" ]]; then
  p_new_type='prod'
fi

. cwt/extensions/remote/remote/exec.sh "$p_remote_id" \
  "cwt/instance/switch_type.sh $p_new_type && cwt/instance/restart.sh"
