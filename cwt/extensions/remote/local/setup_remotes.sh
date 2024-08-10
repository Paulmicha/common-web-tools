#!/usr/bin/env bash

##
# Re-generates (local) remote instances definitions.
#
# @see scripts/cwt/local/remote-instances/${REMOTE_ID}.sh
#
# @example
#   make local-setup-remotes
#   # Or :
#   cwt/extensions/remote/local/setup_remotes.sh
#

. cwt/bootstrap.sh

u_remote_instances_setup
