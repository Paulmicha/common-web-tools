#!/usr/bin/env bash

##
# CWT remote instance init action.
#
# Will attempt to create the remote PROJECT_DOCROOT dir if it doesn't exist yet.
# Will attempt to clone current git origin in remote PROJECT_DOCROOT dir if it
# is empty.
#
# @param 1 String : remote instance ID.
# @param ... all the memaining params are forwarded to cwt/instance/init.sh (but
#   the host type is preset to 'remote')
#
# @example
#   # Initializes a new remote instance of type 'dev' without interactive
#   # terminal prompts :
#   cwt/extensions/remote/remote/init.sh 'dev' -t 'dev' -y
#

. cwt/bootstrap.sh

remote_id="$1"
shift

u_remote_instance_load "$remote_id"

if [[ -z "$REMOTE_INSTANCE_CONNECT_CMD" ]]; then
  echo >&2
  echo "Error in u_remote_exec_wrapper() - $BASH_SOURCE line $LINENO: no conf found for remote id '$remote_id'." >&2
  echo "-> Aborting (1)." >&2
  echo >&2
  exit 1
fi

# Use current git remote 'origin' in case the remote dir is empty.
git_origin="$(git config --get remote.origin.url)"

# We'll need to run multiple instructions in a single connection.
cmds=()
cmds+=("( [[ ! -d $REMOTE_INSTANCE_PROJECT_DOCROOT ]] && mkdir -p $REMOTE_INSTANCE_PROJECT_DOCROOT )")
cmds+=("cd $REMOTE_INSTANCE_PROJECT_DOCROOT")
cmds+=("( [[ -z \\\"\\\$(ls -A)\\\" ]] && git clone '$git_origin' . )")
cmds+=("cwt/instance/init.sh -y -h 'remote'")

joined_str=''
u_str_join " && " "${cmds[@]}"

remote_command="$joined_str $@"

# Debug.
# echo "$remote_command"

eval "$REMOTE_INSTANCE_CONNECT_CMD \"$remote_command\""
