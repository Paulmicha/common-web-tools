#!/usr/bin/env bash

##
# CWT remote ssh key auth action.
#
# @example
#   cwt/remote/ssh_key_auth.sh 'my_short_id'
#

. cwt/bootstrap.sh
u_remote_authorize_ssh_key "$@"
