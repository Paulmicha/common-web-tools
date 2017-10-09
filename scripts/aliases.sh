#!/bin/bash

##
# Local project custom aliases.
#
# Load from project root dir :
# $ . scripts/aliases.sh
#

alias drush="drush --root=./web"

# Make an alias to ssh to project's remote host.
if [ -f ".remote_hosts.env" ]; then
  if [ ! -z $REMOTE_HOST_SSH_PORT ]; then
    alias ssh_prh="ssh -p${REMOTE_HOST_SSH_PORT} ${REMOTE_HOST_USER}@${REMOTE_HOST}"
  else
    alias ssh_prh="ssh ${REMOTE_HOST_USER}@${REMOTE_HOST}"
  fi
fi

# Potential override from 'scripts/specific' dir.
if [ -f scripts/specific/aliases.sh ]; then
  . scripts/specific/aliases.sh
fi
