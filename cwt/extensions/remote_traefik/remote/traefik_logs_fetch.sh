#!/usr/bin/env bash

##
# Downloads traefik logs from a remote 'dev' type instance.
#
# @param 1 [optional] String : the remote instance ID. Defaults to 'prod'.
#
# @example
#   # From 'prod' :
#   make remote-traefik-logs-fetch
#   # Or :
#   cwt/extensions/remote_traefik/remote/traefik_logs_fetch.sh
#
#   # Specify target remote instance :
#   make remote-traefik-logs-fetch 'stage'
#   # Or :
#   cwt/extensions/remote_traefik/remote/traefik_logs_fetch.sh 'stage'
#

. cwt/bootstrap.sh

p_remote_id="$1"

if [[ -z "$p_remote_id" ]]; then
  p_remote_id='prod'
fi

u_remote_check_id "$p_remote_id"

if [[ ! -d "data/logs/remote/$p_remote_id" ]]; then
  mkdir -p "data/logs/remote/$p_remote_id"
fi

datestamp="$(date +"%Y-%m-%d.%H-%M-%S")"

u_remote_download "$p_remote_id" \
  "data/logs/traefik.log" \
  "data/logs/remote/$p_remote_id/${datestamp}.traefik.log"
