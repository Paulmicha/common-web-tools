#!/usr/bin/env bash

##
# Instance-related utility functions.
#
# See cwt/env/README.md
#
# This file is dynamically loaded.
# @see cwt/bootstrap.sh
#
# Convention : functions names are all prefixed by "u" (for "utility").
#

##
# Instance initialization process ("instance init").
#
# @exports GLOBALS
# @exports GLOBALS_COUNT
# @exports GLOBALS_UNIQUE_NAMES
# @exports GLOBALS_UNIQUE_KEYS
# @exports PROJECT_STACK
# @exports PROVISION_USING
# @exports CWT_CUSTOM_DIR
# @exports GLOBALS_FILEPATH
#
# @example
#   # TODO [wip] provide detailed examples.
#   u_instance_init
#
u_instance_init() {
  # Mandatory param (no default fallback provided).
  local p_project_stack=''

  # Default values :
  # @see cwt/env/global.vars.sh
  local p_project_docroot=''
  local p_app_docroot=''
  local p_app_git_origin=''
  local p_app_git_work_tree=''
  local p_instance_type=''
  local p_instance_domain=''

  # Optional remote host(s).
  local p_remote_instances=''
  local p_remote_instances_cmds=''
  local p_remote_instances_types=''

  # Configurable CWT internals.
  local p_host_type=''
  local p_provision_using=''
  local p_deploy_using=''
  local p_cwt_mode=''
  local p_cwt_custom_dir=''

  local p_yes=0
  local p_verbose=0

  while [ "$#" -gt 0 ]; do
    case "$1" in
      -s) p_project_stack="$2"; shift 2;;

      -o) p_project_docroot="$2"; shift 2;;
      -a) p_app_docroot="$2"; shift 2;;
      -g) p_app_git_origin="$2"; shift 2;;
      -i) p_app_git_work_tree="$2"; shift 2;;
      -t) p_instance_type="$2"; shift 2;;
      -d) p_instance_domain="$2"; shift 2;;

      -r) p_remote_instances="$2"; shift 2;;
      -u) p_remote_instances_cmds="$2"; shift 2;;
      -q) p_remote_instances_types="$2"; shift 2;;

      -h) p_host_type="$2"; shift 2;;
      -p) p_provision_using="$2"; shift 2;;
      -e) p_deploy_using="$2"; shift 2;;
      -m) p_cwt_mode="$2"; shift 2;;
      -c) p_cwt_custom_dir="$2"; shift 2;;

      -y) p_yes=1; shift 1;;
      -v) p_verbose=1; shift 1;;

      -*) echo "Error in $BASH_SOURCE line $LINENO: unknown option: $1" >&2; return;;
      *) echo "Notice in $BASH_SOURCE line $LINENO: unsupported unnamed argument: $1" >&2; shift 1;;
    esac
  done

  # Trigger pre-init (optional) extra processes.
  hook -a 'init' -p 'pre'

  export GLOBALS
  export GLOBALS_COUNT
  export GLOBALS_UNIQUE_NAMES
  export GLOBALS_UNIQUE_KEYS

  export PROJECT_STACK="$p_project_stack"
  export PROVISION_USING="$p_provision_using"
  export CWT_CUSTOM_DIR="$p_cwt_custom_dir"
  export GLOBALS_FILEPATH='cwt/env/current/global.vars.sh'

  if [-z "$PROJECT_STACK"] && [$p_yes -eq 0]; then
    read -p "Enter PROJECT_STACK value : " PROJECT_STACK
  fi

  if [[ -z "$PROJECT_STACK" ]]; then
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO: cannot carry on without a value for \$PROJECT_STACK." >&2
    echo "Aborting (1)." >&2
    return 1
  fi

  # Remove previously generated globals to avoid any interference.
  if [[ -f "$GLOBALS_FILEPATH" ]]; then
    rm "$GLOBALS_FILEPATH"
  fi

  # (Re)start dependencies and env vars aggregation.
  unset GLOBALS
  declare -A GLOBALS
  GLOBALS_COUNT=0
  GLOBALS_UNIQUE_NAMES=()
  GLOBALS_UNIQUE_KEYS=()

  # Load default CWT 'core' globals.
  # These contain paths required for aggregating env vars and services.
  . cwt/env/global.vars.sh

  # Discover and aggregate stack services required by this instance.
  export DEPS_LOOKUP_PATHS
  u_stack_get_specs "$PROJECT_STACK"
  if [[ $p_verbose == 1 ]]; then
    u_autoload_print_lookup_paths DEPS_LOOKUP_PATHS "Stack dependencies"
  fi

  # Aggregate en vars for this instance. Needs to run after services discovery
  # and write env vars in current instance's git-ignored settings file.
  u_global_aggregate
  u_global_write

  # Make sure every writeable folders potentially git-ignored gets created
  # before attempting to (re)set their permissions (see below).
  hook -a 'ensure_dirs_exist' -s 'app'

  # (Re)set file system ownership and permissions.
  hook -a 'set_fsop' -s 'app stack service'

  # Trigger post-init (optional) extra processes.
  hook -a 'init' -p 'post'
}

##
# Separates an env item name from its version number.
#
# Follows a simplistic syntax : inputting 'app_test_a-name-test-1.2'
# -> output ['app_test_a-name-test', '1.2']
#
# @param 1 The variable name that will contain the array (in calling scope).
# @param 2 String to separate.
#
# @example
#   u_instance_item_split_version env_item_arr 'app_test_a-name-test-1.2'
#   for item_part in "${env_item_arr[@]}"; do
#     echo "$item_part"
#   done
#
u_instance_item_split_version() {
  local p_var_name="$1"
  local p_str="$2"

  eval "${p_var_name}=()"

  local version_part="${p_str##*-}"

  # If last part doesn't match only numbers and dots, just return [$p_str].
  if [[ ! "$version_part" =~ [0-9.]+$ ]]; then
    eval "${p_var_name}+=(\"$p_str\")"
    return
  fi

  local name_part="${p_str%-*}"

  if [[ -n "$name_part" ]]; then
    eval "${p_var_name}+=(\"$name_part\")"
  fi

  if [[ (-n "$version_part") && ("$version_part" != "$name_part") ]]; then
    eval "${p_var_name}+=(\"$version_part\")"
  fi
}

##
# Gets default value for this project instance's domain.
#
# Some projects may have DNS-dependant features to test locally, so we
# provide a default one based on project docroot dirname. In these cases, the
# necessary domains must be added to the device's hosts file (usually located
# in /etc/hosts or C:\Windows\System32\drivers\etc\hosts). Alternatives also
# exist to achieve this.
#
# The generated domain uses 'io' TLD in order to avoid trigger searches from
# some browsers address bars (like Chrome's).
#
u_get_instance_domain() {
  local lh="$(u_get_localhost_ip)"

  if [[ -z "$lh" ]]; then
    lh='local'
  fi

  if [[ $lh == "192.168."* ]]; then
    lh="${lh//192.168./lan-}"
  else
    lh="host-${lh}"
  fi

  echo "${PWD##*/}.${lh//./-}.io"
}
