#!/usr/bin/env bash

##
# Reads the automatically generated Http Baic Auth crendentials grom given remote.
#
# @param 1 [optional] String : the remote instance ID. Defaults to 'prod'.
#
# @example
#   # From 'prod' :
#   make remote-get-basic-auth
#   # Or :
#   cwt/extensions/remote_traefik/remote/get_basic_auth.sh
#
#   # Specify target remote instance :
#   make remote-get-basic-auth 'stage'
#   # Or :
#   cwt/extensions/remote_traefik/remote/get_basic_auth.sh 'stage'
#

p_remote_id="$1"

if [[ -z "$p_remote_id" ]]; then
  p_remote_id='prod'
fi

cwt/extensions/remote/remote/exec.sh "$p_remote_id" \
  cwt/instance/registry_get.sh 'traefik_basic_auth_creds'
