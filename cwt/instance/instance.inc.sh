#!/usr/bin/env bash

##
# Instance-related utility functions.
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
# @exports PROVISION_USING
# @exports PROJECT_SCRIPTS
# @exports GLOBALS_FILEPATH
#
# @example
#   # TODO [wip] provide detailed examples.
#   u_instance_init
#
u_instance_init() {
  # Default values :
  # @see cwt/env/global.vars.sh
  local p_project_docroot=''
  local p_app_docroot=''
  local p_app_git_origin=''
  local p_app_git_work_tree=''
  local p_instance_type=''
  local p_instance_domain=''

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
      -o) p_project_docroot="$2"; shift 2;;
      -a) p_app_docroot="$2"; shift 2;;
      -g) p_app_git_origin="$2"; shift 2;;
      -i) p_app_git_work_tree="$2"; shift 2;;
      -t) p_instance_type="$2"; shift 2;;
      -d) p_instance_domain="$2"; shift 2;;

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
  hook -p 'pre' -a 'init'

  export GLOBALS
  export GLOBALS_COUNT
  export GLOBALS_UNIQUE_NAMES
  export GLOBALS_UNIQUE_KEYS

  export PROVISION_USING="$p_provision_using"
  export PROJECT_SCRIPTS="$p_cwt_custom_dir"
  export GLOBALS_FILEPATH='cwt/env/current/global.vars.sh'

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

  # Aggregate en vars for this instance. Needs to run after services discovery
  # and write env vars in current instance's git-ignored settings file.
  u_global_aggregate
  u_global_write

  # Make sure every writeable folders potentially git-ignored gets created
  # before attempting to (re)set their permissions (see below).
  hook -a 'ensure_dirs_exist' -s 'app instance'

  # (Re)set file system ownership and permissions.
  hook -a 'set_fsop' -s 'app instance'

  # Trigger instance init (optional) extra processes.
  hook -a 'init' -v 'PROVISION_USING INSTANCE_TYPE HOST_TYPE'
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

  if [ -n "$name_part" ]; then
    eval "${p_var_name}+=(\"$name_part\")"
  fi

  if [ -n "$version_part" ] && [ "$version_part" != "$name_part" ]; then
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
u_instance_domain() {
  local lh="$(u_host_ip)"

  if [ -z "$lh" ]; then
    lh='local'
  fi

  if [[ $lh == "192.168."* ]]; then
    lh="${lh//192.168./lan-}"
  else
    lh="host-${lh}"
  fi

  echo "${PWD##*/}.${lh//./-}.io"
}

##
# [abstract] Sets instance-level registry value.
#
# Writes to an abstract instance-level storage by given key. "Abstract" means that
# CWT core itself doesn't provide any actual implementation for this
# functionality. It is necessary to use an extension which does. E.g. :
# @see cwt/extensions/file_registry
#
# @example
#   u_instance_registry_set 'my_key' 1
#
u_instance_registry_set() {
  local reg_key="$1"
  local reg_val=$2

  # Allows empty values (in which case this entry acts as a boolean flag).
  if [[ -z "$reg_val" ]]; then
    reg_val=1
  fi

  # NB : any implementation of this hook MUST use the reg_val and reg_key
  # variables (which are restricted to this function scope).
  u_hook_most_specific -s 'instance' -a 'registry_set' -v 'INSTANCE_TYPE HOST_TYPE'
}

##
# [abstract] Gets instance-level registry value.
#
# Reads from an abstract instance-level storage by given key. "Abstract" means that
# CWT core itself doesn't provide any actual implementation for this
# functionality. It is necessary to use an extension which does. E.g. :
# @see cwt/extensions/file_registry
#
# NB : for performance reasons (to avoid using a subshell), this function
# writes its result to a variable subject to collision in calling scope.
#
# @var reg_val
#
# @example
#   u_instance_registry_get 'my_key'
#   echo "$reg_val" # <- Prints the value if there is an entry for 'my_key'.
#
u_instance_registry_get() {
  local reg_key="$1"

  # Prevents risks of intereference between multiple calls (since we reuse the
  # same variable).
  unset reg_val

  # NB : any implementation of this hook MUST set its result using the reg_val
  # variable, in this case NOT restricted to this function scope.
  u_hook_most_specific -s 'instance' -a 'registry_get' -v 'INSTANCE_TYPE HOST_TYPE'
}

##
# [abstract] Deletes instance-level registry value.
#
# Removes given entry from an abstract instance-level storage by given key.
# "Abstract" means that CWT core itself doesn't provide any actual
# implementation for this functionality. It is necessary to use an extension
# which does. E.g. :
# @see cwt/extensions/file_registry
#
# @example
#   u_instance_registry_del 'my_key'
#
u_instance_registry_del() {
  local reg_key="$1"

  # NB : any implementation of this hook MUST use the reg_key variable (which is
  # restricted to this function scope).
  u_hook_most_specific -s 'instance' -a 'registry_del' -v 'INSTANCE_TYPE HOST_TYPE'
}

##
# Prevents running something more than once for current project instance.
#
# TODO use variable in calling scope instead of subshell (because currently,
# given the use of the condition in examples below, anything printed out to
# stdin would be evaluated).
#
# Checks boolean flag for this instance.
# @see u_instance_registry_get()
# @see u_instance_registry_set()
#
# @example
#   # When you need to proceed inside the condition :
#   if $(u_instance_once "my_once_id"); then
#     echo "Proceed."
#   else
#     echo "Notice in $BASH_SOURCE line $LINENO : this has already been run on this instance."
#     echo "-> Aborting."
#     exit
#   fi
#
#   # When you need to stop/exit inside the condition :
#   if ! $(u_instance_once "my_once_id"); then
#     echo "Notice in $BASH_SOURCE line $LINENO: already run for current project instance."
#     echo "-> Aborting."
#     exit
#   fi
#
u_instance_once() {
  local p_flag="$1"

  # TODO check what happens in case of unexpected collisions (if that var
  # already exists in calling scope).
  local reg_val

  u_instance_registry_get "$p_flag"

  if [[ $reg_val -ne 1 ]]; then
    u_instance_registry_set "$p_flag"
    return
  fi

  false
}
