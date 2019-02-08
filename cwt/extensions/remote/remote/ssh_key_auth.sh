#!/usr/bin/env bash

##
# CWT remote ssh key auth action.
#
# @example
#   make remote-ssh-key-auth 'my_short_id'
#   # Or :
#   cwt/extensions/remote/remote/ssh_key_auth.sh 'my_short_id'
#

. cwt/bootstrap.sh
u_remote_authorize_ssh_key "$@"
