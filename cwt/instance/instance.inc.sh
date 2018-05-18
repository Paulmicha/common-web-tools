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
# @exports GLOBALS_INTERACTIVE
# @exports GLOBALS_DRY_RUN
# @exports PROVISION_USING
# @exports PROJECT_SCRIPTS
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
  local p_cwt_mode=''
  local p_project_scripts_dir=''

  local p_yes=0
  local p_dry_run=0

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -o) p_project_docroot="$2"; shift 2;;
      -a) p_app_docroot="$2"; shift 2;;
      -g) p_app_git_origin="$2"; shift 2;;
      -i) p_app_git_work_tree="$2"; shift 2;;
      -t) p_instance_type="$2"; shift 2;;
      -d) p_instance_domain="$2"; shift 2;;

      -h) p_host_type="$2"; shift 2;;
      -p) p_provision_using="$2"; shift 2;;
      -m) p_cwt_mode="$2"; shift 2;;
      -c) p_project_scripts_dir="$2"; shift 2;;

      -y) p_yes=1; shift 1;;
      -r) p_dry_run=1; shift 1;;

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
  export GLOBALS_INTERACTIVE
  export GLOBALS_DRY_RUN

  export PROVISION_USING="$p_provision_using"
  export PROJECT_SCRIPTS="$p_project_scripts_dir"

  # (Re)start dependencies and env vars aggregation.
  unset GLOBALS
  declare -A GLOBALS
  GLOBALS_COUNT=0
  GLOBALS_UNIQUE_NAMES=()
  GLOBALS_UNIQUE_KEYS=()
  GLOBALS_INTERACTIVE=$p_yes
  GLOBALS_DRY_RUN=$p_dry_run

  # Load default CWT 'core' globals.
  # These contain paths required for aggregating env vars and services.
  . cwt/env/global.vars.sh

  u_global_aggregate
  u_global_write

  u_instance_write_mk

  # Make sure every writeable folders potentially git-ignored gets created
  # before attempting to (re)set their permissions (see below).
  hook -s 'app instance' -a 'ensure_dirs_exist'

  # (Re)set file system ownership and permissions.
  hook -s 'app instance' -a 'set_fsop'

  # Trigger instance init (optional) extra processes.
  hook -a 'init' -v 'PROVISION_USING HOST_TYPE INSTANCE_TYPE'
}

##
# Converts given string to a task name - e.g. for use as Make task.
#
# During conversion, some terms are abbreviated - e.g. :
#   - registry -> reg
#   - lookup-path -> lp
#   - docker-compose -> dc
#   - docker4drupal -> d4d
#
# TODO [minor] provide ability to set these from extensions.
#
# @param 1 String : input to convert.
# @param 2 [optional] String : the variable name in calling scope which will be
#   assigned the result. Defaults to 'task'.
#
# @var [default] task
#
u_instance_task_name() {
  local p_str="$1"
  local p_itn_var_name="$2"

  if [[ -z "$p_itn_var_name" ]]; then
    p_itn_var_name='task'
  fi

  u_str_sanitize "$p_str" '-' 'p_str' '[^a-zA-Z0-9]'

  p_str="${p_str//registry/reg}"
  p_str="${p_str//lookup-path/lp}"
  p_str="${p_str//docker-compose/dc}"
  p_str="${p_str//docker4drupal/d4d}"

  printf -v "$p_itn_var_name" '%s' "$p_str"
}

##
# Aggregates subject-action entry points and adds them as Make tasks.
#
# Generates a Makefile include with tasks corresponding to every subject-action
# in current instance.
#
u_instance_write_mk() {
  local extension
  local extension_actions
  local extension_namespace

  # From our "entry point" scripts' path, we need to provide a unique task
  # name -> we use subject-action pairs while preventing potential collisions
  # in case different extensions implement the same subject-action pair.
  # Important note : the arrays 'mk_tasks' and 'mk_entry_points' must have the
  # exact same order and size.
  local mk_tasks=()
  local mk_entry_points=()
  local index

  local task
  local sa_pair

  # No need to check for collisions in CWT core (we know there aren't any).
  for sa_pair in $CWT_ACTIONS; do
    task=''
    u_instance_task_name "$sa_pair"
    mk_tasks+=("$task")
    mk_entry_points+=("cwt/$sa_pair.sh")
  done

  for extension in $CWT_EXTENSIONS; do
    u_cwt_extension_namespace "$extension"
    eval "extension_actions=\"\$${extension_namespace}_ACTIONS\""
    if [[ -n "$extension_actions" ]]; then

      # Extensions' subject-action pairs must yield unique tasks -> check for
      # collisions.
      for sa_pair in $extension_actions; do
        task=''
        u_instance_task_name "$sa_pair"

        if u_in_array "$task" 'mk_tasks'; then
          task="${extension}-$task"
          u_instance_task_name "$task"
        fi

        mk_tasks+=("$task")
        mk_entry_points+=("cwt/extensions/$extension/$sa_pair.sh")
      done

    fi
  done

  if [[ -z "$mk_entry_points" ]]; then
    return
  fi

  echo "Writing generic Makefile include cwt/env/current/default.mk ..."

  # (Re)init destination file (make empty).
  cat > cwt/env/current/default.mk <<'EOF'

##
# Current instance Makefile include.
#
# Contains generic tasks for subject-action entry points (default scripts).
#
# This file is automatically generated during "instance init", and it will be
# entirely overwritten every time it is executed.
#
# @see u_instance_init() in cwt/instance/instance.inc.sh
# @see u_instance_write_mk() in cwt/instance/instance.inc.sh
#

EOF

  # for entry_point in $mk_entry_points; do
  # for entry_point in "${mk_entry_points[@]}"; do
  for index in "${!mk_entry_points[@]}"; do
    task="${mk_tasks[index]}"

    echo ".PHONY: $task
$task:
	@ ${mk_entry_points[index]} \$(filter-out \$@,\$(MAKECMDGOALS))
" >> cwt/env/current/default.mk

  done

  echo "Writing generic Makefile include cwt/env/current/default.mk : done."
  echo
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

  # Disallow empty keys.
  if [[ -z "$reg_key" ]]; then
    echo >&2
    echo "Error in u_instance_registry_set() - $BASH_SOURCE line $LINENO: key is required." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    exit 1
  fi

  # Allows empty values (in which case this entry acts as a boolean flag).
  if [[ -z "$reg_val" ]]; then
    reg_val=1
  fi

  # NB : any implementation of this hook MUST use the reg_val and reg_key
  # variables (which are restricted to this function scope).
  u_hook_most_specific -s 'instance' -a 'registry_set' -v 'HOST_TYPE INSTANCE_TYPE'
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
  u_hook_most_specific -s 'instance' -a 'registry_get' -v 'HOST_TYPE INSTANCE_TYPE'
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
  u_hook_most_specific -s 'instance' -a 'registry_del' -v 'HOST_TYPE INSTANCE_TYPE'
}

##
# Prevents running something more than once for current project instance.
#
# Checks boolean flag for this instance.
# @see u_instance_registry_get()
# @see u_instance_registry_set()
#
# @example
#   # When you need to proceed inside the condition :
#   if u_instance_once "my_once_id" ; then
#     echo "Proceed."
#   else
#     echo "Notice in $BASH_SOURCE line $LINENO : this has already been run on this instance."
#     echo "-> Aborting."
#     exit
#   fi
#
#   # When you need to stop/exit inside the condition :
#   if ! u_instance_once "my_once_id" ; then
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
