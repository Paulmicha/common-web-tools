#!/usr/bin/env bash

##
# Reads the Traefik dashboard Http Basic Auth crendentials from given remote.
#
# @param 1 [optional] String : the remote instance ID. Defaults to 'prod'.
#
# @example
#   # From 'prod' :
#   make remote-traefik-basic-auth
#   # Or :
#   cwt/extensions/remote_traefik/remote/traefik_basic_auth.sh
#
#   # Specify target remote instance :
#   make remote-traefik-basic-auth 'stage'
#   # Or :
#   cwt/extensions/remote_traefik/remote/traefik_basic_auth.sh 'stage'
#

p_remote_id="$1"

if [[ -z "$p_remote_id" ]]; then
  p_remote_id='prod'
fi

cwt/extensions/remote/remote/exec.sh "$p_remote_id" \
  cwt/instance/registry_get.sh 'traefik_dashboard_creds'
