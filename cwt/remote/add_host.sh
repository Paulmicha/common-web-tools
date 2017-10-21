#!/bin/bash

##
# Adds a remote host.
#
# Every local instance keeps a list of remote hosts in a gitignored file located
# in project dir : '.remote_hosts.env'.
#
# [wip] For now, only support single remote host par projet.
#
# Usage from project root dir :
# $ . cwt/remote/add_host.sh
#

. cwt/env/load.sh

# Warn when adding new host when one already exists (override).
# @evol manage several hosts (per instance type ?)
if [ -f ".remote_hosts.env" ]; then
  echo ""
  echo "Found existing .remote_hosts.env file in project root dir."

  while true; do
    read -p "Override existing host ? Type 'y' for yes or 'n' for no : " yn
    case $yn in
      [Yy]* ) echo "Ok, proceeding to override existing host."; break;;
      [Nn]* ) echo "Aborting."; return;;
      * ) echo "Please answer yes or no.";;
    esac
  done

  echo ""
fi

read -p "Enter the remote host domain or (IP) address : " NEW_HOST

if [[ ! -z $NEW_HOST ]]; then
  # Generate default host name based on its slugified address or domain.
  NEW_HOST_NAME=$(u_slugify_u "$NEW_HOST")

  # Prompt for optional customization.
  read -p "[optional] Enter a unique machine name - using characters 0-9a-zA-Z_ - for this host (default : ${NEW_HOST_NAME}) : " input_host_name

  if [[ ! -z $input_host_name ]]; then
    NEW_HOST_NAME=$input_host_name
  fi
fi

# Prompt for remote host user (SSH login).
read -p "Enter the remote host user (SSH login) : " NEW_HOST_USER

# Do not proceed without valid input.
if [[ (-z $NEW_HOST) || (-z $NEW_HOST_NAME) || (-z $NEW_HOST_USER) ]]; then
  echo ""
  echo "Aborting : nothing inputted."
  echo ""
  return
fi

# [wip] For now, only support single remote host per projet.
# @evol manage several hosts (per instance type ?)
cat > .remote_hosts.env <<EOF

REMOTE_HOST=$NEW_HOST
REMOTE_HOST_NAME=$NEW_HOST_NAME
REMOTE_HOST_USER=$NEW_HOST_USER

EOF

# @evol implement dynamic ansible\hosts.yml updates (PROVISION='ansible') ?
