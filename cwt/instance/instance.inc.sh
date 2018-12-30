#!/usr/bin/env bash

##
# Instance-related utility functions.
#
# This file is sourced during core CWT bootstrap.
# @see cwt/bootstrap.sh
#
# Convention : functions names are all prefixed by "u" (for "utility").
#

##
# Instance initialization process ("instance init").
#
# This is the first action to execute in any project instance in order to make
# CWT useful. It generates readonly global (env) vars, default Git hooks
# implementations, and convenience "make" shortcuts for all subjects & actions.
#
# @see u_global_aggregate()
# @see u_global_write()
# @see u_instance_write_mk()
#
# @example
#   # Calling this script without any arguments will use prompts in terminal
#   # to provide values for every globals.
#   u_instance_init
#
#   # Initializes an instance of type 'dev', host type 'local', provisionned
#   # using 'ansible', identified by domain 'dev.cwt.com', with git origin
#   # 'git@my-git-origin.org:my-git-account/cwt.git', app sources cloned in 'dist',
#   # and using 'dist/web' as app dir - without terminal prompts (-y flag).
#   u_instance_init \
#     -t 'dev' \
#     -h 'local' \
#     -p 'ansible' \
#     -d 'dev.cwt.com' \
#     -g 'git@my-git-origin.org:my-git-account/cwt.git' \
#     -i 'dist' \
#     -a 'dist/web' \
#     -y
#
u_instance_init() {
  # Default values :
  # @see cwt/env/global.vars.sh
  local p_cwtii_project_docroot=''
  local p_cwtii_app_docroot=''
  local p_cwtii_app_git_origin=''
  local p_cwtii_app_git_work_tree=''
  local p_cwtii_instance_type=''
  local p_cwtii_instance_domain=''

  # Configurable CWT internals.
  local p_cwtii_host_type=''
  local p_cwtii_provision_using=''
  local p_cwtii_project_scripts_dir=''

  local p_cwtii_yes=0
  local p_cwtii_dry_run=0

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -o) p_cwtii_project_docroot="$2"; shift 2;;
      -a) p_cwtii_app_docroot="$2"; shift 2;;
      -g) p_cwtii_app_git_origin="$2"; shift 2;;
      -i) p_cwtii_app_git_work_tree="$2"; shift 2;;
      -t) p_cwtii_instance_type="$2"; shift 2;;
      -d) p_cwtii_instance_domain="$2"; shift 2;;

      -h) p_cwtii_host_type="$2"; shift 2;;
      -p) p_cwtii_provision_using="$2"; shift 2;;
      -c) p_cwtii_project_scripts_dir="$2"; shift 2;;

      -y) p_cwtii_yes=1; shift 1;;
      -r) p_cwtii_dry_run=1; shift 1;;

      -*) echo "Error in $BASH_SOURCE line $LINENO: unknown option: $1" >&2; return;;
      *) echo "Notice in $BASH_SOURCE line $LINENO: unsupported unnamed argument: $1" >&2; shift 1;;
    esac
  done

  if [[ -n "$p_cwtii_project_docroot" ]]; then
    PROJECT_DOCROOT="$p_cwtii_project_docroot"
  fi

  # Trigger pre-init (optional) extra processes.
  hook -p 'pre' -a 'init'

  # (Re)start global vars aggregation.
  unset GLOBALS
  declare -A GLOBALS
  GLOBALS_COUNT=0
  GLOBALS_UNIQUE_NAMES=()
  GLOBALS_UNIQUE_KEYS=()

  # Load default CWT 'core' globals.
  # These contain paths required for aggregating env vars and services.
  . cwt/env/global.vars.sh

  u_global_aggregate

  # If we want to test instance init (when "dry run" flag is set), nothing is
  # written and hooks are replaced by a prefixed variant.
  if [[ $p_cwtii_dry_run -eq 1 ]]; then
    u_global_debug
    hook -s 'app instance' -a 'ensure_dirs_exist' -p 'dry_run'
    hook -s 'app instance' -a 'set_fsop' -p 'dry_run'
    hook -a 'init' -v 'PROVISION_USING HOST_TYPE INSTANCE_TYPE' -p 'dry_run'
    return
  fi

  u_global_write

  u_instance_write_mk

  # Trigger instance init (optional) extra processes.
  hook -a 'init' -v 'PROVISION_USING HOST_TYPE INSTANCE_TYPE'

  # Make sure every writeable folders potentially git-ignored gets created
  # before attempting to (re)set their permissions (see below).
  hook -s 'app instance' -a 'ensure_dirs_exist'

  # (Re)set file system permissions.
  u_instance_set_permissions
}

##
# (Re)sets filesystem permissions.
#
# This chain of hooks is meant for extensions (+ overrides) to provide and
# apply permissions of files and folders for current instance, according to its
# type, host type, and provisionning method.
#
# Additionally, the following globals may be used to specify lists of specific
# paths (non-mutable / declared like any other CWT global) :
# - PROTECTED_FILES : e.g. path to sensitive settings file(s).
# - EXECUTABLE_FILES : e.g. custom app-related scripts.
# - WRITEABLE_DIRS : e.g. path to folders (files, tmp, private) that must be
#     writeable by the application.
# - WRITEABLE_FILES : additional files (outside of WRITEABLE_DIRS) that must be
#     writeable by the application.
#
# By default, CWT resets all files and folders permissions in project root dir.
# It also applies the corresponding permissions to any list of paths optionally
# defined in globals (env vars) mentionned above.
#
# @see u_instance_get_permissions()
# @see cwt/instance/fix_perms.sh
# @see cwt/instance/fs_perms_set.hook.sh
#
# To verify which files can be used (and will be sourced) when these hooks are
# triggered, in this order :
# $ make hook-debug s:app instance a:fs_perms_get v:PROVISION_USING HOST_TYPE INSTANCE_TYPE
# $ make hook-debug s:app instance a:fs_perms_pre_set v:PROVISION_USING HOST_TYPE INSTANCE_TYPE
# $ make hook-debug s:app instance a:fs_perms_set v:PROVISION_USING HOST_TYPE INSTANCE_TYPE
# $ make hook-debug s:app instance a:fs_perms_post_set v:PROVISION_USING HOST_TYPE INSTANCE_TYPE
#
# There is also a convenience 'make' shortcut to reset all permissions.
#
# @example
#   make fix_perms
#   # Or :
#   cwt/instance/fix_perms.sh
#
u_instance_set_permissions() {
  u_instance_get_permissions

  hook -s 'app instance' \
    -a 'fs_perms_pre_set' \
    -v 'PROVISION_USING HOST_TYPE INSTANCE_TYPE'

  hook -s 'app instance' \
    -a 'fs_perms_set' \
    -v 'PROVISION_USING HOST_TYPE INSTANCE_TYPE'

  hook -s 'app instance' \
    -a 'fs_perms_post_set' \
    -v 'PROVISION_USING HOST_TYPE INSTANCE_TYPE'
}

##
# Gets filesystem ownership and permissions settings.
#
# By convention, these are specified using the following (mutable) variables in
# calling scope :
#
# FS_NW_FILES : [optional] permissions to apply to Non-Writeable files.
#   Defaults to 0644.
# FS_NW_DIRS : [optional] permissions to apply to Non-Writeable folders.
#   Defaults to 0755.
# FS_P_FILES : [optional] permissions to apply to Protected files.
#   Defaults to 0444.
# FS_E_FILES : [optional] permissions to apply to Exectuable files.
#   Defaults to 0755.
# FS_W_FILES : [optional] permissions to apply to Writeable files.
#   Defaults to 0774.
# FS_W_DIRS: [optional] permissions to apply to Writeable folders.
#   Defaults to 1771.
#
# To verify which files can be used (and will be sourced) to declare these vars :
# $ make hook-debug s:app instance a:fs_perms_get v:PROVISION_USING HOST_TYPE INSTANCE_TYPE
#
# @example
#   u_instance_get_permissions
#   # Show the result :
#   echo "file permissions = $FS_NW_FILES"
#   echo "folder permissions = $FS_NW_DIRS"
#   echo "writeable file permissions = $FS_W_FILES"
#   echo "writeable folder permissions = $FS_W_DIRS"
#   echo "protected file permissions = $FS_P_FILES"
#   echo "executable file permissions = $FS_E_FILES"
#
u_instance_get_permissions() {
  hook -s 'app instance' \
    -a 'fs_perms_get' \
    -v 'PROVISION_USING HOST_TYPE INSTANCE_TYPE'

  if [[ -z "$FS_NW_FILES" ]]; then
    FS_NW_FILES='0644'
  fi
  if [[ -z "$FS_NW_DIRS" ]]; then
    FS_NW_DIRS='0755'
  fi

  if [[ -z "$FS_W_FILES" ]]; then
    FS_W_FILES='0774'
  fi
  if [[ -z "$FS_W_DIRS" ]]; then
    FS_W_DIRS='1774'
  fi

  if [[ -z "$FS_P_FILES" ]]; then
    FS_P_FILES='0444'
  fi

  if [[ -z "$FS_E_FILES" ]]; then
    FS_E_FILES='0755'
  fi
}

##
# (Re)sets filesystem ownership.
#
# This chain of hooks is meant for extensions (+ overrides) to provide and
# apply ownership of files and folders for current instance, according to its
# type, host type, and provisionning method.
#
# By default, CWT resets all files and folders ownership in project root dir.
# It also applies the corresponding ownership to any list of paths optionally
# defined in globals (env vars) mentionned above.
#
# @see u_instance_get_ownership()
# @see cwt/instance/fix_ownership.sh
# @see cwt/instance/fs_ownership_set.hook.sh
#
# To verify which files can be used (and will be sourced) when these hooks are
# triggered, in this order :
# $ make hook-debug s:app instance a:fs_ownership_get v:PROVISION_USING HOST_TYPE INSTANCE_TYPE
# $ make hook-debug s:app instance a:fs_ownership_pre_set v:PROVISION_USING HOST_TYPE INSTANCE_TYPE
# $ make hook-debug s:app instance a:fs_ownership_set v:PROVISION_USING HOST_TYPE INSTANCE_TYPE
# $ make hook-debug s:app instance a:fs_ownership_post_set v:PROVISION_USING HOST_TYPE INSTANCE_TYPE
#
# There is also a convenience 'make' shortcut to reset all permissions.
#
# @example
#   make fix_ownership
#   # Or :
#   cwt/instance/fix_ownership.sh
#
u_instance_set_ownership() {
  u_instance_get_ownership

  hook -s 'app instance' \
    -a 'fs_ownership_pre_set' \
    -v 'PROVISION_USING HOST_TYPE INSTANCE_TYPE'

  hook -s 'app instance' \
    -a 'fs_ownership_set' \
    -v 'PROVISION_USING HOST_TYPE INSTANCE_TYPE'

  hook -s 'app instance' \
    -a 'fs_ownership_post_set' \
    -v 'PROVISION_USING HOST_TYPE INSTANCE_TYPE'
}

##
# Gets filesystem ownership settings.
#
# By convention, these are specified using the following (mutable) variables in
# calling scope :
#
# FS_OWNER : [optional] owner of all files and dirs.
#   Defaults to current user, even if sudoing.
# FS_GROUP : [optional] group ownership of all files and dirs.
#   Defaults to $FS_OWNER.
# FS_W_OWNER : [optional] owner of Writeable files and dirs.
#   Defaults to $FS_OWNER.
# FS_W_GROUP : [optional] group ownership of Writeable files and dirs.
#   Defaults to $FS_W_OWNER.
#
# To verify which files can be used (and will be sourced) to declare these vars :
# $ make hook-debug s:app instance a:fs_ownership_get v:PROVISION_USING HOST_TYPE INSTANCE_TYPE
#
# @example
#   u_instance_get_ownership
#   # Show the result :
#   echo "ownership = $FS_OWNER:$FS_GROUP"
#   echo "ownership for writeable files/dirs = $FS_W_OWNER:$FS_W_GROUP"
#
u_instance_get_ownership() {
  hook -s 'app instance' -a 'fs_ownership_get' -v 'PROVISION_USING HOST_TYPE INSTANCE_TYPE'

  # Deal with optional values (defaults).
  if [[ -z "$FS_OWNER" ]]; then
    # Get current user even if sudoing.
    # See https://stackoverflow.com/questions/1629605/getting-user-inside-shell-script-when-running-with-sudo
    FS_OWNER="$(logname 2>/dev/null || echo $SUDO_USER)"
  fi
  if [[ -z "$FS_GROUP" ]]; then
    FS_GROUP="$FS_OWNER"
  fi
  if [[ -z "$FS_W_OWNER" ]]; then
    FS_W_OWNER="$FS_OWNER"
  fi
  if [[ -z "$FS_W_GROUP" ]]; then
    FS_W_GROUP="$FS_W_OWNER"
  fi
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

  if [[ -n "$CWT_MAKE_TASKS_SHORTER" ]]; then
    local search_replace_pattern=''
    for search_replace_pattern in $CWT_MAKE_TASKS_SHORTER; do
      u_str_sanitize "$search_replace_pattern" '' 'search_replace_pattern' '[^a-zA-Z0-9\/\-_]'
      eval "p_str=\"\${p_str//$search_replace_pattern}\""
    done
  fi

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

    # The 'instance' subject is a special case : we remove it for CWT core tasks
    # to explicitly make it the default subject. All actions belonging to the
    # 'instance' subject from CWT core are transformed to the action part alone.
    # Exception : instance-init -> init = already hardcoded, so prevent adding
    # it twice.
    # @see cwt/instance/init.make.sh
    # @see Makefile (the one in PROJECT_DOCROOT path).
    case "$task" in instance-*)
      case "$task" in instance-init)
        continue
      esac
      task="${task#*instance-}"
    esac

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
