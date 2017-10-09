#!/bin/bash

##
# Add Local SSH keys to remote host(s) authorized keys.
#
# Prerequisites:
# - Local SSH keys created and loaded in local shell session (ssh-agent).
#
# This script will :
# - Add remote host to local "known_hosts" by connecting once via ssh.
# - Send public key to remote server user's "authorized_keys" file.
#
# Note : these steps will prompt for confirmation and/or passwords. After it's
# done, ssh and drush aliases should work without these prompts.
#
# Usage :
# $ . scripts/remote/authorize_key.sh
#

. scripts/env/load.sh

# Do not proceed without having set the remote host up.
if [ ! -f ".remote_hosts.env" ]; then
  echo ""
  echo "Aborting : missing project remote host vars."
  echo "You can add it using the following command :"
  echo ". scripts/remote/add_host.sh"
  echo ""
  return
fi

# Check we have a public key.
if ! [ -e ~/.ssh/id_rsa.pub ] ; then
  echo ""
  echo "Aborting : an SSH keypair for current user ($USER) must exist."
  echo "E.g. generate with command : ssh-keygen -t rsa"
  echo ""
  return
fi

# Check this hasn't been run before.
THIS_ABS_PATH=$(u_get_script_path ${BASH_SOURCE[0]})
if $(u_check_once "${THIS_ABS_PATH} ${1}"); then
  echo ""
  echo "Proceeding to authorize key for '${1}'. Please confirm and/or connect in the following steps."
else
  echo ""
  echo "Aborting : '${THIS_ABS_PATH} ${1}' has already been run, and must run only once per host per user."
  echo ""
  return
fi

# Verify SSH agent is running. If not, launch it.
# Note : if a passphrase was used to generate the key, this will prompt for it.
if [ -z "$SSH_AUTH_SOCK" ] ; then
  echo ""
  echo "Launch ssh-agent and load the key in your current terminal session."
  echo ""

  eval `ssh-agent -s`
  ssh-add
fi

echo ""
echo "Add remote to 'known_hosts' (if it's the first time a connexion is made), and login using password for user '$REMOTE_HOST_USER' when asked below :"
echo ""

# Send public key to remote server user's "authorized_keys" file.
cat ~/.ssh/id_rsa.pub | ssh_prh 'cat >> .ssh/authorized_keys'

echo ""
echo "Ok, now the following call should not prompt for password, and should print the IP address of the remote host '$REMOTE_HOST' :"
echo ""

ssh_prh -t ip route get 1

echo ""
echo "Over."
echo ""
