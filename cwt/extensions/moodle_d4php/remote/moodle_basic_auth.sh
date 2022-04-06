#!/usr/bin/env bash

##
# Reads the Docker4Druapl Http Basic Auth crendentials from given remote.
#
# @param 1 [optional] String : the remote instance ID. Defaults to 'dev'.
#
# @example
#   # From a remote instance identified by 'dev' :
#   make remote-moodle-basic-auth
#   # Or :
#   cwt/extensions/moodle_d4php/remote/moodle_basic_auth.sh
#
#   # Specify target remote instance :
#   make remote-moodle-basic-auth 'stage'
#   # Or :
#   cwt/extensions/moodle_d4php/remote/moodle_basic_auth.sh 'stage'
#

p_remote_id="$1"

if [[ -z "$p_remote_id" ]]; then
  p_remote_id='dev'
fi

cwt/extensions/remote/remote/exec.sh "$p_remote_id" \
  cwt/instance/registry_get.sh 'moodle_basic_auth_creds'
