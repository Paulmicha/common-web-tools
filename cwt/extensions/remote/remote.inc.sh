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
#     and REMOTE_INSTANCE_DOCROOT (remotely)
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
#   # Allow non-blocking "file not found" errors by setting this var in calling
#   # scope :
#   remote_download_skip_errors='true'
#   u_remote_download 'my_short_id' /remote/file.ext /local/dir/
#
u_remote_download() {
  local p_id="$1"
  local p_remote_path="$2"
  local p_local_path="$3"
  shift 3

  u_remote_instance_load "$p_id"

  if [[ -z "$REMOTE_INSTANCE_SSH_CONNECT_CMD" ]]; then
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
    p_remote_path="$REMOTE_INSTANCE_DOCROOT/$p_remote_path"
  fi

  # Make sure local dir exists.
  local local_dir="$p_local_path"
  if [[ ! "${local_dir:(-1)}" = '/' ]]; then
    local_dir="${local_dir%/*}"
  fi
  if [[ ! -d "$local_dir" ]]; then
    mkdir -p "$local_dir"
    if [[ $? -ne 0 ]]; then
      echo >&2
      echo "Error in $BASH_SOURCE line $LINENO: unable to create local dir where remote file will be stored." >&2
      echo >&2
      exit 1
    fi
  fi

  # Debug.
  # echo "scp ${REMOTE_INSTANCE_SSH_USER}@${REMOTE_INSTANCE_HOST}:$p_remote_path $p_local_path $@"

  scp "${REMOTE_INSTANCE_SSH_USER}@${REMOTE_INSTANCE_HOST}:$p_remote_path" "$p_local_path" "$@"

  if [[ $? -ne 0 ]]; then
    if [[ -z "$remote_download_skip_errors" ]]; then
      echo >&2
      echo "Error in $BASH_SOURCE line $LINENO: the command 'scp' exited with a non-zero status." >&2
      echo >&2
      exit 2
    fi
  else
    echo "Download successfully completed."
  fi
}

##
# Uploads a file or dir to given remote dir (include last slash) or filepath.
#
# Important notes:
#   - when providing relative paths, the reference is PROJECT_DOCROOT (locally)
#     and REMOTE_INSTANCE_DOCROOT (remotely)
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
#   u_remote_upload 'my_short_id' local-file.ext remote-file.ext
#
#   # Upload an entire dir (recursively).
#   u_remote_upload 'my_short_id' /local/dir /remote/dir -r
#
#   # Do not overrite existing files on the remote.
#   u_remote_upload 'my_short_id' /path/to/file.ext /remote/dir/ --ignore-existing
#
u_remote_upload() {
  local p_id="$1"
  local p_local_path="$2"
  local p_remote_path="$3"
  shift 3

  u_remote_instance_load "$p_id"

  if [[ -z "$REMOTE_INSTANCE_SSH_CONNECT_CMD" ]]; then
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
    p_remote_path="$REMOTE_INSTANCE_DOCROOT/$p_remote_path"
  fi

  if [[ "$1" == '--ignore-existing' ]]; then
    local uru_host_part=''
    if [[ -n "$REMOTE_INSTANCE_SSH_USER" ]]; then
      uru_host_part="${REMOTE_INSTANCE_SSH_USER}@${REMOTE_INSTANCE_HOST}"
    else
      uru_host_part="$REMOTE_INSTANCE_HOST"
    fi
    rsync -vau "$p_local_path" "$uru_host_part:${p_remote_path}"
  else
    scp "$p_local_path" "${REMOTE_INSTANCE_SSH_USER}@${REMOTE_INSTANCE_HOST}:${p_remote_path}" $@
  fi

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
# Executes commands remotely from local instance.
#
# @param 1 String : remote instance's id (short name, no space, _a-zA-Z0-9 only).
# @param ... The rest will be forwarded to the script.
#
# @example
#   u_remote_exec_wrapper my_short_id git status
#   u_remote_exec_wrapper my_short_id make globals-lp
#   u_remote_exec_wrapper my_short_id cwt/test/cwt/global.test.sh
#
u_remote_exec_wrapper() {
  local p_id="$1"
  shift 1

  u_remote_instance_load "$p_id"

  if [[ -z "$REMOTE_INSTANCE_SSH_CONNECT_CMD" ]]; then
    echo >&2
    echo "Error in u_remote_exec_wrapper() - $BASH_SOURCE line $LINENO: no SSH connection defined for remote id '$p_id'." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    return 1
  fi

  # Always execute remotely from REMOTE_INSTANCE_DOCROOT, and inject the remote
  # exec commands prefix code (if any is defined in given remote instance).
  local remote_cmd="$REMOTE_INSTANCE_SSH_EXEC_PREFIX cd $REMOTE_INSTANCE_DOCROOT && $@"

  if [[ -z "$REMOTE_INSTANCE_SSH_EXEC_PREFIX" ]]; then
    remote_cmd="cd $REMOTE_INSTANCE_DOCROOT && $@"
  fi

  # Debug
  # echo "$REMOTE_INSTANCE_SSH_CONNECT_CMD \"$remote_cmd\""

  $REMOTE_INSTANCE_SSH_CONNECT_CMD "$remote_cmd"
}

##
# Replaces tokens from any remote instance definition value.
#
# TODO additional argument to specify into which variable to write the result ?
#
# Any value from the same definition can be used directly as a token. E.g. in
# the following YAML definition :
# ```yml
#
# prod:
#   host: 1.2.3.4
#   docroot: /var/www/foobar
#   domain: foobar.com
#   dumps:
#     default:
#       base_dir: /path/to/dumps
#       file: '{{ %Y-%m-%d.%H-%M-%S }}_site_{{ DOMAIN }}'
#
# ```
# - The {{ DOMAIN }} will be replaced by 'foobar.com'.
# - Any global var (env) can also be used here.
# - The {{ %Y-%m-%d.%H-%M-%S }} part will be replaced by '2024-07-25.11-16-11'.
#
# This writes its result to a variable subject to collision in calling scope.
# @var tokens_replaced
#
# @param 1 String : remote instance's id (e.g. 'prod').
# @param 2 String : input string containing tokens to replace.
# @param 3 [optional] Int : recursive calls counter. Because there are tokens
#   that may point to values that also contain tokens, this function calls
#   itself at the end to traverse all the tokens. But we need to be able to
#   break out of the recursion if a token cannot get replaced due to missing
#   value.
#
# @example
#   tokens_replaced=''
#   u_remote_definition_tokens_replace 'prod' '{{ %Y-%m-%d.%H-%M-%S }}_site_{{ DOMAIN }}'
#   echo "$tokens_replaced" # yields for example : '2024-07-25.11-16-11_site_foobar.com'
#
u_remote_definition_tokens_replace() {
  local p_remote_id="$1"
  local p_input_str="$2"
  local p_circuit_breaker=0

  if [[ -z "$p_remote_id" ]]; then
    echo >&2
    echo "Error in u_remote_definition_tokens_replace() - $BASH_SOURCE line $LINENO: param 1 (p_remote_id) is required." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    return 1
  fi

  if [[ -z "$p_input_str" ]]; then
    echo >&2
    echo "Error in u_remote_definition_tokens_replace() - $BASH_SOURCE line $LINENO: param 2 (p_input_str) is required." >&2
    echo "-> Aborting (2)." >&2
    echo >&2
    return 2
  fi

  if [[ $3 -gt $p_circuit_breaker ]]; then
    p_circuit_breaker=$3
  fi

  # Only load remote instance definitions if necessary.
  if [[ -z "$REMOTE_INSTANCE_ID" ]] || [[ "$REMOTE_INSTANCE_ID" != "$p_remote_id"  ]]; then
    u_remote_instance_load "$p_remote_id"
  fi

  # Start with the raw input, which we will gradually transform below.
  tokens_replaced="$p_input_str"

  # First, any value from the same definition can be used directly as a token.
  local var=''
  local val=''
  local KEY=''
  local keys=()
  local token=''

  u_remote_definition_get_keys

  for key in "${keys[@]}"; do
    var="remote_instance_$key"
    u_str_uppercase "$key" 'KEY'
    u_str_uppercase "$var" 'var'
    val="${!var}"
    token="{{ $KEY }}"

    # Debug.
    # case "$key" in 'domain')
    #   echo "var = '$var'"
    #   echo "  token = '$token'"
    #   echo "  val = '$val'"
    #   echo "  before :"
    #   echo "    $tokens_replaced"
    # esac

    tokens_replaced="${tokens_replaced//$token/$val}"

    # Debug.
    # case "$key" in 'domain')
    #   echo "  after :"
    #   echo "    $tokens_replaced"
    # esac
  done

  # Same for any global var.
  u_global_list

  for var in "${cwt_globals_var_names[@]}"; do
    val="${!var}"
    token="{{ $var }}"

    # Debug.
    # echo "var = '$var'"
    # echo "  token = '$token'"
    # echo "  val = '$val'"

    tokens_replaced="${tokens_replaced//$token/$val}"
  done

  # The {{ %Y-%m-%d.%H-%M-%S }} part(s) must be replaced by current datestamp.
  local match=''
  local regex_loop_str="$tokens_replaced"
  local regex="\{\{[[:space:]]*([^[:space:]]+)[[:space:]]*\}\}"

  while [[ "$regex_loop_str" =~ $regex ]]; do
    token="${BASH_REMATCH[0]}"
    match="${BASH_REMATCH[1]}"

    # For the while loop to get all tokens, it needs to be gradually pruned.
    regex_loop_str="${regex_loop_str#*$token}"

    # Anything with a '%' character is considered a date formatter.
    case "$match" in *'%'*)
      val="$(date +"$match")"

      # Debug.
      # echo "token = '$token'"
      # echo "  val = '$val'"

      tokens_replaced="${tokens_replaced//$token/$val}"
    esac
  done

  # There are tokens that may point to values that also contain tokens.
  case "$tokens_replaced" in *'{{ '*)
    # Up to 9 recursions is probably more than enough.
    if [[ $p_circuit_breaker -lt 10 ]]; then
      p_circuit_breaker+=1
      u_remote_definition_tokens_replace "$p_remote_id" "$tokens_replaced" $p_circuit_breaker
    else
      echo "Notice : breaking out of u_remote_definition_tokens_replace() recursion."
      echo "  $tokens_replaced"
    fi
  esac
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
  hook_most_specific_dry_run_match=''

  u_hook_most_specific 'dry-run' \
    -a 'remote_instances' \
    -c 'yml' \
    -v 'HOST_TYPE INSTANCE_TYPE' \
    -t -r

  # Purge existing remotes first.
  u_remote_purge_instances

  # Having remotes is not required for all instance types.
  if [[ ! -f "$hook_most_specific_dry_run_match" ]]; then
    return
  fi

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
  local parsed_yaml_remotes="$(u_yaml_parse "$hook_most_specific_dry_run_match" 'cwtri_')"
  echo "$parsed_yaml_remotes" >> 'scripts/cwt/local/remote-instances.sh'

  # Process & adapt parsed result for use with u_remote_instance_load().
  if [[ -f 'scripts/cwt/local/remote-instances.sh' ]]; then
    . scripts/cwt/local/remote-instances.sh

    local remote_id
    local var_prefix
    local var
    local val
    local key
    local keys=()

    u_remote_definition_get_keys

    u_yaml_get_root_keys "$hook_most_specific_dry_run_match"

    for remote_id in "${yaml_keys[@]}"; do
      var_prefix="cwtri_${remote_id}"

      # The dictionary stores all the variables to be (re)written in the
      # generated definition file(s) in the end. It's per remote instance, hence
      # we make sure it is empty before attempting to build on it in this loop.
      unset setup_dict
      declare -A setup_dict

      setup_dict[id]="$remote_id"

      for key in "${keys[@]}"; do
        var="${var_prefix}_${key}"
        val="${!var}"

        # Debug
        # echo "$remote_id.$key = '$val' ($var)"

        # TODO [check] see if there are unintended consequences to skip any
        # empty value here.
        if [[ -z "$val" ]]; then
          continue
        fi

        # TODO [evol] see if there's a better workaround for quotes. Right now,
        # we have to trim any ' or " prefix + suffix manually here.
        # @see cwt/vendor/bash-yaml/script/yaml.sh
        val="${val%\'}"
        val="${val#\'}"
        val="${val%\"}"
        val="${val#\"}"

        setup_dict["$key"]="$val"
      done

      # Can't carry on without the host.
      if [[ -z "${setup_dict[host]}" ]]; then
        echo "Notice : there is no 'host' for remote '$remote_id' -> skip setup."
        continue
      fi

      # Deal with fallback values (if available).
      if [[ -z "${setup_dict[ssh_exec_prefix]}" ]] \
        && [[ -n "$CWT_REMOTE_SSH_EXEC_PREFIX" ]]
      then
        setup_dict[ssh_exec_prefix]="$CWT_REMOTE_SSH_EXEC_PREFIX"
      fi

      # Custom tokens, e.g. {{ CURRENT_USER }} must be replaced by the current
      # local user name, even if sudoing.
      # See https://stackoverflow.com/questions/1629605/getting-user-inside-shell-script-when-running-with-sudo
      case "${setup_dict[ssh_user]}" in '{{ CURRENT_USER }}')
        setup_dict[ssh_user]="$(logname 2>/dev/null || echo $SUDO_USER)"
      esac

      # Provide a default SSH connect command.
      if [[ -z "${setup_dict[ssh_connect_cmd]}" ]]; then
        local user_host="${setup_dict[ssh_user]}@${setup_dict[host]}"

        if [[ -z "${setup_dict[ssh_user]}" ]]; then
          user_host="${setup_dict[host]}"
        fi

        # NB : the '-A' flag allows to forward currently loaded SSH keys from
        # the local terminal session. The '-T' flag requests a non-interactive
        # tty (= opens a non-interactive terminal session on remote).
        setup_dict[ssh_connect_cmd]="ssh -T -A $user_host"

        if [[ -n "${setup_dict[ssh_port]}" ]]; then
          setup_dict[ssh_connect_cmd]="ssh -T -A -p${setup_dict[ssh_port]} $user_host"
        fi
      fi

      # Pre-render the remote connection prefix for commands like rsync or scp.
      if [[ -z "${setup_dict[prefix]}" ]]; then
        setup_dict[prefix]="${setup_dict[host]}"

        if [[ -n "${setup_dict[ssh_user]}" ]]; then
          setup_dict[prefix]="${setup_dict[ssh_user]}@${setup_dict[host]}"
        fi
      fi

      # Finally, create the resulting definition file.
      if [[ ! -d 'scripts/cwt/local/remote-instances' ]]; then
        mkdir -p 'scripts/cwt/local/remote-instances'

        if [[ $? -ne 0 ]]; then
          echo >&2
          echo "Error in $BASH_SOURCE line $LINENO: failed to create missing required dir scripts/cwt/local/remote-instances." >&2
          echo "-> Aborting (1)." >&2
          echo >&2
          return 1
        fi
      fi

      local conf="scripts/cwt/local/remote-instances/${remote_id}.sh"

      cat > "$conf" <<EOF
#!/usr/bin/env bash

##
# '$remote_id' remote instance definition file.
#
# This file is automatically generated.
# @see u_remote_instances_setup() in cwt/extensions/remote/remote.inc.sh
#

EOF
      # Write (append) to the generated definition file, escaping single quotes
      # because it's a plain bash script that will be sourced.
      for key in "${!setup_dict[@]}"; do
        var="remote_instance_$key"
        u_str_uppercase "$var" 'var'

        val="${setup_dict[$key]}"
        val="${val//\'/\'\"\'\"\'}" # @link https://stackoverflow.com/a/1250279/2592338

        printf "%s\n" "export $var='$val'" >> "$conf"
      done
    done
  fi
}

##
# Produces an array of keys for remote instance definitions.
#
# This function appends entries to an array which must be initialized in calling
# scope already :
#
# @var keys
#
# @example
#   keys=()
#   u_remote_definition_get_keys
#
#   for key in "${keys[@]}"; do
#     echo "key = $key"
#   done
#
u_remote_definition_get_keys() {
  keys+=('id')
  keys+=('host')
  keys+=('domain')
  keys+=('docroot')
  keys+=('prefix')
  keys+=('ssh_user')
  keys+=('ssh_port')
  keys+=('ssh_exec_prefix')
  keys+=('ssh_connect_cmd')

  # Remote files are a dynamic list of names (suffixes) used to assign variables
  # to folders to sync to and from (anb between) remote instances. It's meant
  # for files that are not part of the versionned app sources, e.g. git-ignored
  # dirs like sites/default/files in Drupal, etc.
  if [[ -n "$CWT_REMOTE_FILES_SUFFIXES" ]]; then
    local suffix=''

    for suffix in $CWT_REMOTE_FILES_SUFFIXES; do
      u_str_sanitize_var_name "$suffix" 'suffix'
      keys+=("data_files_${suffix}_remote")
      keys+=("data_files_${suffix}_local")
    done
  fi

  # The DB-related config entries need dynamic var names.
  # Needs the 'db' CWT extension, which might be disabled, so we check if
  # function is defined.
  if type u_db_get_ids >/dev/null 2>&1 ; then
    local db_id
    local db_ids=()

    u_db_get_ids

    for db_id in "${db_ids[@]}"; do
      keys+=("data_dumps_${db_id}_base_dir")
      keys+=("data_dumps_${db_id}_file")
      keys+=("data_dumps_${db_id}_latest_symlink")
      keys+=("data_dumps_${db_id}_type")
      keys+=("data_dumps_${db_id}_cmd")
    done

    # In order to generate remote commands like mysql dump, in some cases, there
    # are credentials available remotely as env vars (which can be loaded
    # through ssh_exec_prefix if necessary). Hence the use of a mapping
    # definition, so the command can be properly formed (to be able to use the
    # correct remote env vars).
    local var=''
    local vars_to_map='db_driver db_host db_port db_name db_user db_pass db_admin_user db_admin_pass'

    for var in $vars_to_map; do
      keys+=("data_dumps_${db_id}_env_map_${var}")
    done
  fi

  # Allows other extensions to extend the list of keys.
  hook -s 'remote_definition_keys' -a 'alter' -v 'REMOTE_INSTANCE_ID'
}

##
# For any given remote instance, get a single key value.
#
# @param 1 String : remote instance ID.
# @param 2 String : key of the value to read from its definition.
# @param 3 String : name of the variable in calling scope which holds the
#   result.
#
# @example
#   remote_dir=''
#   u_remote_definition_get_key 'prod' 'data_files_private_remote' 'remote_dir'
#   echo "remote_dir = $remote_dir"
#
u_remote_definition_get_key() {
  local p_remote_id="$1"
  local p_key="$2"
  local p_rdgk_var="$3"

  # Only load the remote instance definition if not already loaded.
  if [[ -z "$REMOTE_INSTANCE_ID" || "$REMOTE_INSTANCE_ID" != "$p_remote_id" ]]; then
    u_remote_instance_load "$p_remote_id"
  fi

  local var=''
  local val=''
  local KEY=''

  u_str_uppercase "$p_key" 'KEY'

  var="REMOTE_INSTANCE_$KEY"
  val="${!var}"

  # Skip tokens if empty.
  if [[ -z "$val" ]]; then
    printf -v "$p_rdgk_var" '%s' ""
    return
  fi

  # Replace tokens.
  local tokens_replaced=''
  u_remote_definition_tokens_replace "$p_remote_id" "$val"

  # Write result to var in calling scope.
  printf -v "$p_rdgk_var" '%s' "$tokens_replaced"
}

##
# Gets remote instance config.
#
# @param 1 [optional] String : remote instance's id (short name, no space,
#   _a-zA-Z0-9 only). Defaults to the first *.sh file found in folder :
#   scripts/cwt/local/remote-instances.
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
