#!/usr/bin/env bash

##
# TODO [wip] te re-test.
# CWT remote ssh key auth action.
#
# @param 1 String : the remote ID.
# @param 2 [optional] String : the SSH public key file path.
#   Defaults to "$HOME/.ssh/id_rsa.pub" or "$CWT_SSH_PUBKEY" if not empty.
#
# @example
#   make remote-ssh-key-auth 'my_short_id'
#   # Or :
#   cwt/extensions/remote/remote/ssh_key_auth.sh 'my_short_id'
#

. cwt/bootstrap.sh

p_id="$1"
p_key="$2"

public_key_path="$HOME/.ssh/id_rsa.pub"

if [[ -n "$CWT_SSH_PUBKEY" ]]; then
  public_key_path="$CWT_SSH_PUBKEY"
fi

if [[ -n "$p_key" ]]; then
  public_key_path="$p_key"
fi

u_remote_instance_load "$p_id"

if [[ -z "$REMOTE_INSTANCE_SSH_CONNECT_CMD" ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO: no conf found for remote id '$p_id'." >&2
  echo "-> Aborting (1)." >&2
  echo >&2
  exit 1
fi

# Current $USER must already have a public key.
if [[ ! -f "$public_key_path" ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO: the public key '$public_key_path' was not found." >&2
  echo "E.g. generate with command : ssh-keygen -t rsa" >&2
  echo "-> Aborting (2)." >&2
  echo >&2
  exit 2
fi

# Ensures SSH agent is running with the key loaded.
if [[ -z "$SSH_AUTH_SOCK" ]]; then
  echo "SSH agent is not running (or not detected in $BASH_SOURCE line $LINENO)"
  echo "-> Launching ssh-agent and load the key in current terminal session..."
  echo "Note : if a passphrase was used to generate the key, this will prompt for it."

  eval `ssh-agent -s`
  ssh-add "$public_key_path"

  if [[ $? -ne 0 ]]; then
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO: the command 'ssh-add' exited with a non-zero status." >&2
    echo "-> Aborting (3)." >&2
    echo >&2
    exit 3
  else
    echo "Launching ssh-agent and load the key in current terminal session : done."
  fi
fi

echo
echo "Sending our local key to the remote server 'authorized_keys' file ..."

ssh-copy-id -i "$public_key_path" "$REMOTE_INSTANCE_HOST"

echo "Sending our local key to the remote server 'authorized_keys' file : done."
echo
