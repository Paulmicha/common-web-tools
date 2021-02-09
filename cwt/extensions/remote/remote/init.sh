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
#   cwt/extensions/remote/remote/init.sh 'dev' -t 'dev'
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
# Expected format : user@host.com:path/to/project.git
git_origin="$(git config --get remote.origin.url)"

# Prevent error due to first time connecting to git host(s).
hosts=()
regex="\@([^\:]+)\:"
hosts_with_user=()
regex_with_user="^([^\:]+)\:"

if [[ "$git_origin" =~ $regex ]]; then
  hosts+=("${BASH_REMATCH[1]}")
fi
if [[ "$git_origin" =~ $regex_with_user ]]; then
  hosts_with_user+=("${BASH_REMATCH[1]}")
fi
if [[ -n "$APP_GIT_ORIGIN" ]]; then
  if [[ "$APP_GIT_ORIGIN" =~ $regex ]]; then
    u_array_add_once "${BASH_REMATCH[1]}" hosts
  fi
  if [[ "$APP_GIT_ORIGIN" =~ $regex_with_user ]]; then
    u_array_add_once "${BASH_REMATCH[1]}" hosts_with_user
  fi
fi

# We'll need to run multiple instructions in a single connection.
cmds=()

cmds+=("if [[ -f $REMOTE_INSTANCE_PROJECT_DOCROOT/.git/HEAD ]] ; then echo 'Instance appears to be already initialized.' ; exit ; fi")

if [[ -n "${hosts[@]}" ]] && [[ -n "${hosts_with_user[@]}" ]]; then
  for (( i = 0; i < ${#hosts[@]}; i++ )); do
    cmds+=("( ssh -T ${hosts_with_user[i]} &> /dev/null ; if [[ \\\$? -ne 0 ]]; then ssh-keyscan -H ${hosts[i]} >> ~/.ssh/known_hosts ; echo 'Added ${hosts[i]} to known hosts.' ; else echo 'Ok - ${hosts[i]} appears to authorize connection.' ; fi )")
  done
fi

cmds+=("( [[ ! -d $REMOTE_INSTANCE_PROJECT_DOCROOT ]] && mkdir -p $REMOTE_INSTANCE_PROJECT_DOCROOT )")
cmds+=("cd $REMOTE_INSTANCE_PROJECT_DOCROOT")
cmds+=("( [[ -z \\\"\\\$(ls -A)\\\" ]] && git clone '$git_origin' . )")
cmds+=("cwt/instance/init.sh -y -h 'remote'")

joined_str=''
u_str_join " ; " "${cmds[@]}"

remote_command="$joined_str $@"

# Debug.
# echo "$remote_command"

eval "$REMOTE_INSTANCE_CONNECT_CMD \"$remote_command\""
