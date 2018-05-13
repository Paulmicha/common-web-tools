#!/usr/bin/env bash

##
# Remote host-related utility functions.
#
# TODO implement SSH setup as an action (authorize local user key).
#
# This file is dynamically loaded.
# @see cwt/bootstrap.sh
#

##
# Downloads a file or dir from given remote.
#
# Important notes:
#   - when providing relative paths, the reference is PROJECT_DOCROOT (locally)
#     and REMOTE_INSTANCE_PROJECT_DOCROOT (remotely)
#   - any additional arguments are passed on to the 'scp' command
#
# See https://gist.github.com/dehamzah/ac216f38319d34444487f6375359ad29
#
# @example
#   # Download a single file.
#   u_remote_download 'my_short_id' /remote/file.ext /local/dir/
#   u_remote_download 'my_short_id' /remote/file.ext /local/dir/renamed-file.ext
#
#   # Download a single file using relative paths.
#   u_remote_download 'my_short_id' remote-file.ext local-file.ext
#
#   # Download an entire dir (recursively).
#   u_remote_download 'my_short_id' /remote/dir /local/dir -r
#
u_remote_download() {
  local p_id="$1"
  local p_remote_path="$2"
  local p_local_path="$3"
  shift 3

  u_remote_instance_load "$p_id"

  if [[ -z "$REMOTE_INSTANCE_CONNECT_CMD" ]]; then
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO: no conf found for remote id '$p_id'." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    return 1
  fi

  # Handle relative paths.
  if [[ "${p_local_path:0:1}" != '/' ]]; then
    p_local_path="$PROJECT_DOCROOT/$p_local_path"
  fi
  if [[ "${p_remote_path:0:1}" != '/' ]]; then
    p_remote_path="$REMOTE_INSTANCE_PROJECT_DOCROOT/$p_remote_path"
  fi

  scp "${REMOTE_USER}@${REMOTE_INSTANCE_HOST}:$p_remote_path" "$p_local_path" "$@"

  if [[ $? -ne 0 ]]; then
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO: the command 'scp' exited with a non-zero status." >&2
    echo >&2
    exit 1
  else
    echo "Download successfully completed."
  fi
}

##
# Uploads a file or dir to given remote dir (include last slash) or filepath.
#
# Important notes:
#   - when providing relative paths, the reference is PROJECT_DOCROOT (locally)
#     and REMOTE_INSTANCE_PROJECT_DOCROOT (remotely)
#   - any additional arguments are passed on to the 'scp' command
#
# See https://gist.github.com/dehamzah/ac216f38319d34444487f6375359ad29
#
# @example
#   # Upload a single file.
#   u_remote_upload 'my_short_id' /local/path/to/file.ext /remote/dir/
#   u_remote_upload 'my_short_id' /local/path/to/file.ext /remote/dir/new-file-name.ext
#
#   # Upload a single file using relative paths.
#   u_remote_download 'my_short_id' local-file.ext remote-file.ext
#
#   # Upload an entire dir (recursively).
#   u_remote_upload 'my_short_id' /local/dir /remote/dir -r
#
u_remote_upload() {
  local p_id="$1"
  local p_local_path="$2"
  local p_remote_path="$3"
  shift 3

  u_remote_instance_load "$p_id"

  if [[ -z "$REMOTE_INSTANCE_CONNECT_CMD" ]]; then
    echo >&2
    echo "EFFFLINENO: no conf found for remote id '$p_id'." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    return 1
  fi

  # Handle relative paths.
  if [[ "${p_local_path:0:1}" != '/' ]]; then
    p_local_path="$PROJECT_DOCROOT/$p_local_path"
  fi
  if [[ "${p_remote_path:0:1}" != '/' ]]; then
    p_remote_path="$REMOTE_INSTANCE_PROJECT_DOCROOT/$p_remote_path"
  fi

  scp "$p_local_path" "${REMOTE_USER}@${REMOTE_INSTANCE_HOST}:${p_remote_path}" "$@"

  if [[ $? -ne 0 ]]; then
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO: the command 'scp' exited with a non-zero status." >&2
    echo >&2
    exit 1
  else
    echo "Upload successfully completed."
  fi
}

##
# Add Local SSH keys to remote host(s) authorized keys.
#
# Prerequisites:
# - Local SSH keys created and loaded in local shell session (ssh-agent).
#
# Calling this function will :
# - Add remote host to local "known_hosts" by connecting once via ssh.
# - Send public key to remote server user's "authorized_keys" file.
#
# Note : these steps will prompt for confirmation and/or passwords. After it's
# done, ssh should work without these prompts.
#
# @see u_remote_script_wrapper()
#
# @example
#   u_remote_authorize_ssh_key 'my_short_id'
#
u_remote_authorize_ssh_key() {
  local p_id="$1"
  local p_key="$2"

  local public_key_path="$HOME/.ssh/id_rsa.pub"
  if [[ -n "$p_key" ]]; then
    public_key_path="$p_key"
  fi

  u_remote_instance_load "$p_id"

  if [[ -z "$REMOTE_INSTANCE_CONNECT_CMD" ]]; then
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO: no conf found for remote id '$p_id'." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    return 1
  fi

  # Current $USER must already have a public key.
  if [ ! -f "$public_key_path" ]; then
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO: the public key '$public_key_path' was not found." >&2
    echo "E.g. generate with command : ssh-keygen -t rsa" >&2
    echo "-> Aborting (2)." >&2
    echo >&2
    return 2
  fi

  # Prevent running this more than once per host.
  if ! $(u_host_once "u_remote_authorize_ssh_key.${REMOTE_INSTANCE_HOST}.${USER}.${public_key_path}"); then
    echo
    echo "Notice in $BASH_SOURCE line $LINENO: it appears that key was already sent to that remote host."
    echo "There is no need to send it again."
    echo "-> Aborting (0)."
    echo
    return 0
  fi

  # Ensures SSH agent is running with the key loaded.
  if [ -z "$SSH_AUTH_SOCK" ]; then
    echo "SSH agent is not running (or not detected in $BASH_SOURCE line $LINENO)"
    echo "-> Launching ssh-agent and load the key in current terminal session..."
    echo "Note : if a passphrase was used to generate the key, this will prompt for it."

    eval `ssh-agent -s`
    ssh-add "$public_key_path"

    if [[ $? -ne 0 ]]; then
      echo >&2
      echo "Error in $BASH_SOURCE line $LINENO: the command 'ssh-add' exited with a non-zero status." >&2
      echo "-> Aborting (4)." >&2
      echo >&2
      exit 4
    else
      echo "Launching ssh-agent and load the key in current terminal session : done."
    fi
  fi

  echo
  echo "Sending our local key to the remote server 'authorized_keys' file..."
  echo "Note : this may prompt for confirmation for adding the remote host to the local 'known_hosts' file if it's the first time a connexion is made."
  echo

  eval "cat $public_key_path | $REMOTE_INSTANCE_CONNECT_CMD 'cat >> .ssh/authorized_keys'"

  echo "Ok, now the following call should not prompt for password, and should print the IP address of the remote host '$REMOTE_INSTANCE_HOST' :"
  echo

  eval "$REMOTE_INSTANCE_CONNECT_CMD -t ip route get 1"

  echo "Over."
  echo
}

##
# Executes local scripts remotely.
#
# @param 1 String : remote instance's id (short name, no space, _a-zA-Z0-9 only).
# @param 2 String : file path to local script to execute remotely.
# @param ... The rest will be forwarded to the script.
#
# @requires the following global variables in calling scope :
# - REMOTE_INSTANCE_CONNECT_CMD : a command that MUST accept another command as
#   input - e.g. "ssh -p123 username@example.com".
# - REMOTE_INSTANCE_PROJECT_DOCROOT : path from where that script must be
#   executed on remote host. Useful for situations where a similar filesystem
#   is used, e.g. a partial clone of the same repo lives on the remote host in
#   order to "bootstrap" CWT-based scripts remotely to operate that instance.
#
# TODO provision automatically the following prerequisites during stack init :
# @prereq manual setup on remote (requires a select up-to-date sync of scripts).
# @prereq u_remote_instance_add() already launched locally at least once.
#
# @example
#   u_remote_script_wrapper 'my_short_id' cwt/stack/init.sh -s drupal-7
#
u_remote_script_wrapper() {
  local p_id="$1"
  local p_remote_script="$2"
  shift 2

  if [[ ! -f "$p_remote_script" ]]; then
    echo
    echo "Error in $BASH_SOURCE line $LINENO: file '$p_remote_script' not found." >&2
    echo "Aborting (1)." >&2
    echo
    return 1
  fi

  u_remote_instance_load "$p_id"

  if [[ -z "$REMOTE_INSTANCE_CONNECT_CMD" ]]; then
    echo
    echo "Error in $BASH_SOURCE line $LINENO: no conf found for remote id '$p_id'." >&2
    echo "Aborting (2)." >&2
    echo
    return 2
  fi

  # Remote execution wrapper.
  # See https://unix.stackexchange.com/a/326672 (using the bash or ksh version).
  if [[ -n "$@" ]]; then
    local args
    printf -v args '%q ' "$@"

    eval "$REMOTE_INSTANCE_CONNECT_CMD \"cd $REMOTE_INSTANCE_PROJECT_DOCROOT && bash -s -- $args\" < \"$p_remote_script\""

  else
    eval "$REMOTE_INSTANCE_CONNECT_CMD \"cd $REMOTE_INSTANCE_PROJECT_DOCROOT && bash -s\" < \"$p_remote_script\""
  fi
}

##
# Adds a remote instance.
#
# @param 1 String : remote instance's id (short name, no space, _a-zA-Z0-9 only).
# @param 2 String : remote instance's host domain.
# @param 3 String : remote instance's type (dev, production, etc).
# @param 4 String : remote SSH user.
# @param 5 String : remote instance's PROJECT_DOCROOT value.
# @param 6 [optional] String : remote instance's APP_DOCROOT value. Defaults to:
#   "$p_project_docroot/web"
# @param 7 [optional] Number : SSH port. Defaults to: not specified.
# @param 8 [optional] String : raw command used to connect (including args).
#   Defaults to: 'ssh username@example.com' (or 'ssh -p123 username@example.com'
#   if param 7 is specified).
#
# TODO convert to named args.
#
# @example
#   # Basic example with only mandatory params :
#   u_remote_instance_add \
#     'my_short_id' \
#     'remote.instance.example.com' \
#     'dev' \
#     'username' \
#     '/path/to/remote/instance/docroot'
#
u_remote_instance_add() {
  local p_id="$1"
  local p_host="$2"
  local p_type="$3"
  local p_ssh_user="$4"
  local p_project_docroot="$5"
  local p_app_docroot="$6"
  local p_ssh_port="$7"
  local p_connect_cmd="$8"

  if [[ -z "$p_app_docroot" ]]; then
    p_app_docroot="$p_project_docroot/web"
  fi

  local conf="cwt/remote/instances/${p_id}.sh"

  # Confirm overwriting existing config if the file already exists.
  if [[ -f "$conf" ]]; then
    echo
    while true; do
      echo "It seems the file '$conf' already exists."
      read -p "Overwrite ? (y/n) : " yn
      case $yn in
        [Yy]* ) echo "Ok, proceeding to override existing settings."; break;;
        [Nn]* ) echo "Aborting (1)."; return 1;;
        * ) echo "Please answer yes (enter 'y') or no (enter 'n').";;
      esac
    done
  fi

  local connection_cmd="$p_connect_cmd"
  if [[ -z "$p_connect_cmd" ]]; then
    connection_cmd="ssh ${p_ssh_user}@${p_host}"
    if [[ -n "$p_ssh_port" ]]; then
      connection_cmd="ssh -p${p_ssh_port} ${p_ssh_user}@${p_host}"
    fi
  fi

  # (Re)init destination file (make empty).
  cat > "$conf" <<'EOF'
#!/usr/bin/env bash

##
# Remote instance config file.
#
# This file is automatically generated.
# @see u_remote_instance_add()
#

EOF

  printf "%s" "export REMOTE_INSTANCE_ID='$p_id'" >> "$conf"
  echo '' >> "$conf"
  printf "%s" "export REMOTE_INSTANCE_HOST='$p_host'" >> "$conf"
  echo '' >> "$conf"
  printf "%s" "export REMOTE_INSTANCE_TYPE='$p_type'" >> "$conf"
  echo '' >> "$conf"
  printf "%s" "export REMOTE_INSTANCE_SSH_USER='$p_ssh_user'" >> "$conf"
  echo '' >> "$conf"
  printf "%s" "export REMOTE_INSTANCE_SSH_PORT='$p_ssh_port'" >> "$conf"
  echo '' >> "$conf"
  printf "%s" "export REMOTE_INSTANCE_CONNECT_CMD='$connection_cmd'" >> "$conf"
  echo '' >> "$conf"
  printf "%s" "export REMOTE_INSTANCE_PROJECT_DOCROOT='$p_project_docroot'" >> "$conf"
  echo '' >> "$conf"
  printf "%s" "export REMOTE_INSTANCE_APP_DOCROOT='$p_app_docroot'" >> "$conf"
  echo '' >> "$conf"
}

##
# Gets remote instance config.
#
# @param 1 [optional] String : remote instance's id (short name, no space,
#   _a-zA-Z0-9 only). Defaults to the first *.sh file found in folder :
#   cwt/remote/instances.
#
# @exports REMOTE_INSTANCE_ID
# @exports REMOTE_INSTANCE_HOST
# @exports REMOTE_INSTANCE_TYPE
# @exports REMOTE_INSTANCE_CONNECT_CMD
# @exports REMOTE_INSTANCE_PROJECT_DOCROOT
# @exports REMOTE_INSTANCE_APP_DOCROOT
#
# @example
#   # Only need to call the function for exporting globals in current shell :
#   u_remote_instance_load 'my_short_id'
#
u_remote_instance_load() {
  local p_id="$1"
  local conf="cwt/remote/instances/${p_id}.sh"

  if [[ ! -f "$conf" ]]; then
    echo
    echo "Error in $BASH_SOURCE line $LINENO: file '$conf' not found." >&2
    echo "Aborting (1)." >&2
    echo
    return 1
  fi

  . "$conf"
}
