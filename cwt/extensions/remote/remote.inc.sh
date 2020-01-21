#!/usr/bin/env bash

##
# Remote host-related utility functions.
#
# TODO implement SSH setup as an action (authorize local user key).
#
# This file is sourced during core CWT bootstrap.
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

  scp "${REMOTE_INSTANCE_SSH_USER}@${REMOTE_INSTANCE_HOST}:$p_remote_path" "$p_local_path" "$@"

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
    echo "Error in u_remote_upload() - $BASH_SOURCE line $LINENO: no conf found for remote id '$p_id'." >&2
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

  scp "$p_local_path" "${REMOTE_INSTANCE_SSH_USER}@${REMOTE_INSTANCE_HOST}:${p_remote_path}" "$@"

  if [[ $? -ne 0 ]]; then
    echo >&2
    echo "Error in u_remote_upload() - $BASH_SOURCE line $LINENO: the command 'scp' exited with a non-zero status." >&2
    echo >&2
    exit 2
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
# @see u_remote_exec_wrapper()
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

  # SSH users on the remote may not already have an .ssh dir in their $HOME dir.
  u_remote_exec_wrapper "$p_id" '[ ! -d ~/.ssh ] && mkdir -p ~/.ssh'

  # TODO make idempotent.
  eval "cat $public_key_path | $REMOTE_INSTANCE_CONNECT_CMD 'cat >> .ssh/authorized_keys'"

  echo "Ok, now the following call should not prompt for password, and should print the IP address of the remote host '$REMOTE_INSTANCE_HOST' :"
  echo

  eval "$REMOTE_INSTANCE_CONNECT_CMD -t ip route get 1"

  echo "Over."
  echo
}

##
# Executes commands remotely from local instance.
#
# Important note : any command should work, but not aliases (unless called from
# within a script on the remote).
#
# @param 1 String : remote instance's id (short name, no space, _a-zA-Z0-9 only).
# @param 2 String : command or file path of a script to execute remotely - which
#   is relative to the PROJECT_DOCROOT of that remote instance.
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
#   u_remote_exec_wrapper my_short_id cwt/test/cwt/global.test.sh
#   u_remote_exec_wrapper my_short_id make globals-lp
#   u_remote_exec_wrapper my_short_id git status
#
u_remote_exec_wrapper() {
  local p_id="$1"
  local p_cmd="$2"
  shift 2

  u_remote_instance_load "$p_id"

  if [[ -z "$REMOTE_INSTANCE_CONNECT_CMD" ]]; then
    echo >&2
    echo "Error in u_remote_exec_wrapper() - $BASH_SOURCE line $LINENO: no conf found for remote id '$p_id'." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    return 1
  fi

  # Sanitize command input + args.
  # See https://unix.stackexchange.com/a/326672 (using the bash or ksh version).
  local cmd
  printf -v cmd '%q ' "$p_cmd"

  if [[ $? -ne 0 ]]; then
    echo >&2
    echo "Error in u_remote_exec_wrapper() - $BASH_SOURCE line $LINENO: failed to sanitize given command." >&2
    echo "-> Aborting (2)." >&2
    echo >&2
    return 2
  fi

  # Always execute remotely from REMOTE_INSTANCE_PROJECT_DOCROOT.
  local cmd_prefix="$REMOTE_INSTANCE_CONNECT_CMD \"cd $REMOTE_INSTANCE_PROJECT_DOCROOT &&"
  local cmd_suffix="\""

  if [[ -n "$@" ]]; then
    local p_args
    printf -v p_args '%q ' "$@"

    if [[ $? -ne 0 ]]; then
      echo >&2
      echo "Error in u_remote_exec_wrapper() - $BASH_SOURCE line $LINENO: failed to sanitize given arguments." >&2
      echo "-> Aborting (3)." >&2
      echo >&2
      return 3
    fi

    # echo "$cmd_prefix $cmd $p_args $cmd_suffix"
    eval "$cmd_prefix $cmd $p_args $cmd_suffix"

  else
    # echo "$cmd_prefix $cmd $cmd_suffix"
    eval "$cmd_prefix $cmd $cmd_suffix"
  fi
}

##
# Setup all remote instances at once using YAML file hook: remote_instances.yml
#
# Only the most specific file will be used. This allows to restrict the
# possibility to execute remote calls from certain instances (i.e. non-local
# and/or per instance type).
#
# Prerequisite : in order to use the option 'ssh_use_agent_filter', the
# package 'ssh-agent-filter' must be installed on your local machine.
# @prereq https://git.tiwe.de/ssh-agent-filter.git
#
# To list matches & check which one will be used (the most specific) :
# $ u_hook_most_specific 'dry-run' \
#     -a 'remote_instances' \
#     -c 'yml' \
#     -v 'HOST_TYPE INSTANCE_TYPE' \
#     -t -r -d
#   echo "match = $hook_most_specific_dry_run_match"
#
u_remote_instances_setup() {
  local parsed_yaml_remotes=''
  hook_most_specific_dry_run_match=''

  u_hook_most_specific 'dry-run' \
    -a 'remote_instances' \
    -c 'yml' \
    -v 'HOST_TYPE INSTANCE_TYPE' \
    -t -r

  if [[ -f "$hook_most_specific_dry_run_match" ]]; then
    # Purge existing remotes first.
    u_remote_purge_instances

    # (Re)init destination file (make empty).
    cat > 'scripts/cwt/local/remote-instances.sh' <<EOF
#!/usr/bin/env bash

##
# Remote instances parsed from the following YAML config file :
#
# $hook_most_specific_dry_run_match
#
# This file is automatically generated after "instance init", and it will be
# entirely overwritten every time it is executed.
#
# @see u_remote_instances_setup()
# @see cwt/extensions/remote/instance/post_init.hook.sh
#

EOF

    # Write remotes definitions.
    parsed_yaml_remotes="$(u_yaml_parse "$hook_most_specific_dry_run_match" 'cwtri_')"
    echo "$parsed_yaml_remotes" >> 'scripts/cwt/local/remote-instances.sh'
  fi

  # Process & adapt parsed result for use with u_remote_instance_load().
  if [[ -f 'scripts/cwt/local/remote-instances.sh' ]]; then
    . scripts/cwt/local/remote-instances.sh

    local remote_id
    local var_prefix
    local v
    local host
    local docroot
    local ssh_user
    local ssh_use_agent_filter
    local ssh_pubkey

    u_yaml_get_keys "$parsed_yaml_remotes" 'cwtri_'

    for remote_id in "${yaml_keys[@]}"; do
      var_prefix="cwtri_${remote_id}"
      # u_str_uppercase "$var_prefix" var_prefix

      v="${var_prefix}_host"
      host="${!v}"

      if [[ -z "$host" ]]; then
        continue
      fi

      # echo "$remote_id.host = '$host' ($v)"
      v="${var_prefix}_docroot"
      docroot="${!v}"
      # echo "$remote_id.docroot = '$docroot' ($v)"
      v="${var_prefix}_ssh_user"
      ssh_user="${!v}"
      # echo "$remote_id.ssh_user = '$ssh_user' ($v)"
      v="${var_prefix}_ssh_use_agent_filter"
      ssh_use_agent_filter="${!v}"
      # echo "$remote_id.ssh_use_agent_filter = '$ssh_use_agent_filter' ($v)"
      v="${var_prefix}_ssh_pubkey"
      ssh_pubkey="${!v}"
      # echo "$remote_id.ssh_pubkey = '$ssh_pubkey' ($v)"

      # This option requires installing the package ssh-agent-filter on your
      # local machine.
      # See https://git.tiwe.de/ssh-agent-filter.git
      if [[ -n "$ssh_use_agent_filter" ]]; then
        # We can't setup SSH connection command without a path to a public key.
        if [[ -z "$ssh_pubkey" ]] && [[ -z "$CWT_SSH_PUBKEY" ]]; then
          echo >&2
          echo "Error in u_remote_instances_setup() - $BASH_SOURCE line $LINENO: missing CWT_SSH_PUBKEY env var." >&2
          echo "-> Aborting (1)." >&2
          echo >&2
          exit 1
        else
          # Use the public key path set in YAML file or fallback to env. var.
          if [[ -z "$ssh_pubkey" ]]; then
            ssh_pubkey="$CWT_SSH_PUBKEY"
          fi
          # Do not require a ssh_user.
          local user_host="$ssh_user@$host"
          if [[ -z "$ssh_user" ]]; then
            user_host="$host"
          fi
          u_remote_instance_add \
            "$remote_id" \
            "$host" \
            "$docroot" \
            "$ssh_user" \
            "afssh -f $(u_remote_get_pubkey_hex_md5_fingerprint $ssh_pubkey) -- -T $user_host"
        fi
      else
        u_remote_instance_add \
          "$remote_id" \
          "$host" \
          "$docroot" \
          "$ssh_user"
      fi
    done
  fi
}

##
# Adds a remote instance.
#
# @param 1 String : remote instance's id (short name, no space, _a-zA-Z0-9 only).
# @param 2 String : remote instance's host domain.
# @param 3 String : remote instance's PROJECT_DOCROOT value.
# @param 4 [optional] String : remote SSH user.
#   Defaults to: current user, even if sudoing.
# @param 5 [optional] String : raw command used to connect (including args).
#   Defaults to: 'ssh -T -A username@example.com' (request a non-interactive TTY
#   and enable ssh-agent forwarding).
#
# @example
#   # Basic example with only mandatory params (defaults to current user) :
#   u_remote_instance_add \
#     'my_short_id' \
#     'remote.instance.example.com' \
#     '/path/to/remote/instance/docroot'
#
#   # Example specifying user to use on remote :
#   u_remote_instance_add \
#     'my_short_id' \
#     'remote.instance.example.com' \
#     '/path/to/remote/instance/docroot' \
#     'my_ssh_user'
#
#   # Example with user + SSH connection cmd override (using
#   # ssh-agent-filter) :
#   u_remote_instance_add \
#     'my_short_id' \
#     'remote.instance.example.com' \
#     '/path/to/remote/instance/docroot' \
#     'remote_user' \
#     'afssh -c /home/local_user/.ssh/id_project_name -- -T remote_user@remote.instance.example.com'
#     # Tip : ssh-agent-filter alternative using fingerprint instead of filepath
#     # (workaround some unexpected varying behaviors under some Linux distros) :
#     # "afssh -f $(u_remote_get_pubkey_hex_md5_fingerprint $CWT_SSH_PUBKEY) -- -T remote_user@remote.instance.example.com"
#
u_remote_instance_add() {
  local p_id="$1"
  local p_host="$2"
  local p_project_docroot="$3"
  local p_ssh_user="$4"
  local p_connect_cmd="$5"

  # Update : no longer require user to support custom ssh config.
  # If dynamic fallback is wanted, use '<current-user>'.
  # if [[ -z "$p_ssh_user" ]]; then
  case "$p_ssh_user" in '<current-user>')
    # Get current user even if sudoing.
    # See https://stackoverflow.com/questions/1629605/getting-user-inside-shell-script-when-running-with-sudo
    p_ssh_user="$(logname 2>/dev/null || echo $SUDO_USER)"
  esac
  # fi

  if [[ ! -d 'scripts/cwt/local/remote-instances' ]]; then
    mkdir -p 'scripts/cwt/local/remote-instances'
    if [[ $? -ne 0 ]]; then
      echo >&2
      echo "Error in u_remote_instance_add() - $BASH_SOURCE line $LINENO: failed to create missing required dir scripts/cwt/local/remote-instances." >&2
      echo "-> Aborting (1)." >&2
      echo >&2
      return 1
    fi
  fi

  local conf="scripts/cwt/local/remote-instances/${p_id}.sh"

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

    # Do not require a ssh_user.
    local user_host="$p_ssh_user@$p_host"
    if [[ -z "$p_ssh_user" ]]; then
      user_host="$p_host"
    fi

    # NB : the '-A' flag allows to forward currently loaded SSH keys from
    # the local terminal session. The '-T' flag requests a non-interactive
    # tty (= opens a non-interactive terminal session on remote).
    connection_cmd="ssh -T -A $user_host"

    if [[ -n "$p_ssh_port" ]]; then
      connection_cmd="ssh -T -A -p$p_ssh_port $user_host"
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

  printf "%s\n" "export REMOTE_INSTANCE_ID='$p_id'" >> "$conf"
  printf "%s\n" "export REMOTE_INSTANCE_HOST='$p_host'" >> "$conf"
  printf "%s\n" "export REMOTE_INSTANCE_SSH_USER='$p_ssh_user'" >> "$conf"
  printf "%s\n" "export REMOTE_INSTANCE_CONNECT_CMD='$connection_cmd'" >> "$conf"
  printf "%s\n" "export REMOTE_INSTANCE_PROJECT_DOCROOT='$p_project_docroot'" >> "$conf"
}

##
# Gets remote instance config.
#
# @param 1 [optional] String : remote instance's id (short name, no space,
#   _a-zA-Z0-9 only). Defaults to the first *.sh file found in folder :
#   scripts/cwt/local/remote-instances.
#
# @exports REMOTE_INSTANCE_ID
# @exports REMOTE_INSTANCE_HOST
# @exports REMOTE_INSTANCE_SSH_USER
# @exports REMOTE_INSTANCE_CONNECT_CMD
# @exports REMOTE_INSTANCE_PROJECT_DOCROOT
#
# @example
#   # Only need to call the function for exporting globals in current shell :
#   u_remote_instance_load 'my_short_id'
#
u_remote_instance_load() {
  local p_id="$1"
  local conf="scripts/cwt/local/remote-instances/${p_id}.sh"

  if [[ ! -f "$conf" ]]; then
    echo >&2
    echo "Error in u_remote_instance_load() - $BASH_SOURCE line $LINENO: file '$conf' not found." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    return 1
  fi

  . "$conf"
}

##
# Purges all local generated remotes.
#
# @example
#   u_remote_purge_instances
#
u_remote_purge_instances() {
  u_fs_file_list 'scripts/cwt/local/remote-instances'
  for file in $file_list; do
    rm "scripts/cwt/local/remote-instances/$file"
    if [[ $? -ne 0 ]]; then
      echo >&2
      echo "Error in u_remote_purge_instances() - $BASH_SOURCE line $LINENO: failed to remove locally generated instance '$file' (in scripts/cwt/local/remote-instances)." >&2
      echo "-> Aborting (1)." >&2
      echo >&2
      return 1
    fi
  done
}

##
# Gets given SSH public key's hex-encoded md5 fingerprint.
#
# See https://superuser.com/questions/1088165/get-ssh-key-fingerprint-in-old-hex-format-on-new-version-of-openssh
# + https://github.com/tiwe-de/ssh-agent-filter
#
# @example
#   connect_cmd="afssh -f $(u_remote_get_pubkey_hex_md5_fingerprint $HOME/.ssh/id_rsa.pub) -- -T my_user@my_host"
#
u_remote_get_pubkey_hex_md5_fingerprint() {
  local p_public_key_file="$1"

  if [[ ! -f "$p_public_key_file" ]]; then
    echo >&2
    echo "Error in u_remote_get_pubkey_hex_md5_fingerprint() - $BASH_SOURCE line $LINENO: public key not found or not accessible." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    return 1
  fi

  awk '{print $2}' "$p_public_key_file" | base64 -d | md5sum | sed 's/../&:/g; s/: .*$//'
}
