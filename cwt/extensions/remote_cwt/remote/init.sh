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
#   cwt/extensions/remote_cwt/remote/init.sh 'dev' -t 'dev'
#

. cwt/bootstrap.sh

remote_id="$1"
u_remote_check_id "$remote_id"
shift

u_remote_instance_load "$remote_id"

if [[ -z "$REMOTE_INSTANCE_SSH_CONNECT_CMD" ]]; then
  echo >&2
  echo "Error in u_remote_exec_wrapper() - $BASH_SOURCE line $LINENO: no conf found for remote id '$remote_id'." >&2
  echo "-> Aborting (1)." >&2
  echo >&2
  exit 1
fi

# If the remote instance was already initialized :
# - make sure it is up to date (git pull)
# - uninit so it can be reinit below using given arguments
# Otherwise, carry on with the initial git cloning - making sure beforehand that
# the git host(s) are included in ~/.ssh/known_hosts on the remote.
# This prevents errors due to first time connecting to this/those git host(s).

# Use current git remote 'origin' in case the remote dir is empty.
# Expected format : user@host.com:path/to/project.git
git_origin="$(git config --get remote.origin.url)"

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

# This part of the command needs to be dynamically generated.
dyn_cmd_known_hosts=''

if [[ -n "${hosts[@]}" ]] && [[ -n "${hosts_with_user[@]}" ]]; then
  for (( i = 0; i < ${#hosts[@]}; i++ )); do
    dyn_cmd_known_hosts+="

  ssh -T ${hosts_with_user[i]} &> /dev/null
  if [[ \$? -ne 0 ]]; then
    ssh-keyscan -H ${hosts[i]} >> ~/.ssh/known_hosts
    echo 'Added ${hosts[i]} to known hosts.'
  else
    echo 'Ok - ${hosts[i]} appears to authorize connection.'
  fi

"
  done
fi

# Assemble and execute the command remotely.
# cat <<REMOTECMD
eval "$REMOTE_INSTANCE_SSH_CONNECT_CMD" bash <<REMOTECMD

if [[ -f $REMOTE_INSTANCE_DOCROOT/.git/HEAD ]]; then

  echo 'Instance appears to be already initialized.'
  echo '-> Make sure it is up to date, and reinit using given arguments.'

  cd $REMOTE_INSTANCE_DOCROOT
  git pull
  cwt/instance/uninit.sh

else
$dyn_cmd_known_hosts

  if [[ ! -d $REMOTE_INSTANCE_DOCROOT ]]; then
    echo 'Create the remote PROJECT_DOCROOT dir.'
    mkdir -p $REMOTE_INSTANCE_DOCROOT
  fi

  if [[ ! -f $REMOTE_INSTANCE_DOCROOT/.git/HEAD ]]; then
    echo 'Clone current git origin in remote PROJECT_DOCROOT dir.'
    git clone '$git_origin' $REMOTE_INSTANCE_DOCROOT
  fi
fi

REMOTECMD

# Workaround : launch the "init" action separately. Fixes unknown issue where
# running this inside the "inline" command above appeared to be skipped on first
# call.
. cwt/extensions/remote_cwt/remote/exec.sh "$remote_id" \
  "cwt/instance/init.sh -y -h 'remote' $@"
