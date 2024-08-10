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
# CWT useful. It generates readonly global (env) vars, optional Git hooks
# implementations, and convenience "make" shortcuts for all subjects & actions.
#
# @see u_global_aggregate()
# @see u_global_write()
# @see u_make_generate()
#
# Gotcha : when calling this function in an already initialized instance, given
# its design, every 'append' type globals values would pile-up, creating
# duplicate values. Workaround :
# @see cwt/instance/reinit.sh
#
# @example
#   # Calling this script without any arguments will use prompts in terminal
#   # to provide values for every globals.
#   u_instance_init
#
#   # Initializes an instance of type 'dev', host type 'local', provisionned
#   # using 'ansible', identified by domain 'dev.cwt.com', using 'cwt_dev' as
#   # docker-compose namespace, with git origin
#   'git@my-git-origin.org:my-git-account/cwt.git', app sources cloned in 'dist',
#   # and using 'dist/web' as app dir - without terminal prompts (-y flag).
#   u_instance_init \
#     -t 'dev' \
#     -h 'local' \
#     -p 'ansible' \
#     -d 'dev.cwt.com' \
#     -c 'cwt_dev' \
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
  local p_cwtii_server_docroot=''
  local p_cwtii_instance_type=''
  local p_cwtii_instance_domain=''
  local p_cwtii_dc_ns=''

  # Configurable CWT internals.
  local p_cwtii_host_type=''
  local p_cwtii_provision_using=''

  local p_cwtii_yes=0
  local p_cwtii_dry_run=0

  # Reads values optionally provided in YAML config file (for now, just the ones
  # in PROJECT_DOCROOT dir).
  yaml_parsed_sp_init=''
  yaml_parsed_globals=''
  if [[ -f "cwt.yml" ]] || [[ -f ".cwt-local.yml" ]]; then
    if [[ -f "cwt.yml" ]]; then
      u_instance_yaml_config_parse "cwt.yml"
    fi
    if [[ -f ".cwt-local.yml" ]]; then
      u_instance_yaml_config_parse ".cwt-local.yml"
    fi
    if [[ -n "$yaml_parsed_sp_init" ]]; then
      eval "$yaml_parsed_sp_init"

      # TODO support all globals for reinits ? For ex. as in :
      # @see u_traefik_generate_acme_conf() in cwt/extensions/remote_traefik/remote_traefik.inc.sh
      if [[ -n "$YAML_APP_GIT_ORIGIN" ]]; then
        p_cwtii_app_git_origin="$YAML_APP_GIT_ORIGIN"
      fi
      if [[ -n "$YAML_SERVER_DOCROOT" ]]; then
        p_cwtii_server_docroot="$YAML_SERVER_DOCROOT"
      fi
      if [[ -n "$YAML_APP_DOCROOT" ]]; then
        p_cwtii_app_docroot="$YAML_APP_DOCROOT"
      fi
      if [[ -n "$YAML_INSTANCE_DOMAIN" ]]; then
        p_cwtii_instance_domain="$YAML_INSTANCE_DOMAIN"
      fi
      if [[ -n "$YAML_DC_NS" ]]; then
        p_cwtii_dc_ns="$YAML_DC_NS"
      fi
    fi
  fi

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -o) p_cwtii_project_docroot="$2"; shift 2;;
      -a) p_cwtii_app_docroot="$2"; shift 2;;
      -s) p_cwtii_server_docroot="$2"; shift 2;;
      -g) p_cwtii_app_git_origin="$2"; shift 2;;
      -t) p_cwtii_instance_type="$2"; shift 2;;
      -d) p_cwtii_instance_domain="$2"; shift 2;;
      -c) p_cwtii_dc_ns="$2"; shift 2;;

      -h) p_cwtii_host_type="$2"; shift 2;;
      -p) p_cwtii_provision_using="$2"; shift 2;;

      -y) p_cwtii_yes=1; shift 1;;
      -r) p_cwtii_dry_run=1; shift 1;;

      -*) echo "Error in $BASH_SOURCE line $LINENO: unknown option: $1" >&2; return;;
      *) echo "Notice in $BASH_SOURCE line $LINENO: unsupported unnamed argument: $1" >&2; shift 1;;
    esac
  done

  if [[ -n "$p_cwtii_project_docroot" ]]; then
    PROJECT_DOCROOT="$p_cwtii_project_docroot"
  fi

  # (Re)start global vars aggregation.
  unset GLOBALS
  declare -A GLOBALS
  GLOBALS_COUNT=0
  GLOBALS_UNIQUE_NAMES=()
  GLOBALS_UNIQUE_KEYS=()
  GLOBALS_DEFERRED=()
  GLOBALS['.defer-max']=0

  # Load default CWT 'core' globals.
  # These contain paths required for aggregating env vars and services.
  . cwt/env/global.vars.sh

  # Any global vars defined in YAML takes precedence. Use the dynamic lookup now
  # that we have values for HOST_TYPE and INSTANCE_TYPE (for variants).
  # Allow by default the use of local overrides by placing variants in dedicated
  # folder.
  # TODO [evol] allow template-like syntax in those for easier combinations ?
  if [[ -f "scripts/cwt/override/.cwt-local.$HOST_TYPE.yml" ]]; then
    if [[ -f ".cwt-local.$HOST_TYPE.yml" ]]; then
      rm -f ".cwt-local.$HOST_TYPE.yml"
    fi
    cp "scripts/cwt/override/.cwt-local.$HOST_TYPE.yml" ".cwt-local.$HOST_TYPE.yml"
  fi

  if [[ -f "scripts/cwt/override/.cwt-local.$INSTANCE_TYPE.yml" ]]; then
    if [[ -f ".cwt-local.$INSTANCE_TYPE.yml" ]]; then
      rm -f ".cwt-local.$INSTANCE_TYPE.yml"
    fi
    cp "scripts/cwt/override/.cwt-local.$INSTANCE_TYPE.yml" ".cwt-local.$INSTANCE_TYPE.yml"
  fi

  if [[ -f "scripts/cwt/override/.cwt-local.$HOST_TYPE.$INSTANCE_TYPE.yml" ]]; then
    if [[ -f ".cwt-local.$HOST_TYPE.$INSTANCE_TYPE.yml" ]]; then
      rm -f ".cwt-local.$HOST_TYPE.$INSTANCE_TYPE.yml"
    fi
    cp "scripts/cwt/override/.cwt-local.$HOST_TYPE.$INSTANCE_TYPE.yml" ".cwt-local.$HOST_TYPE.$INSTANCE_TYPE.yml"
  fi

  yaml_parsed_sp_init=''
  yaml_parsed_globals=''

  u_instance_yaml_config_load

  if [[ -n "$yaml_parsed_globals" ]]; then
    eval "$yaml_parsed_globals"

    if [[ $? -ne 0 ]]; then
      echo "  Aborting(1)" >&2
      exit 1
    fi
  fi

  # Normal process runs after YAML globals.
  u_global_aggregate

  # If we want to test instance init (when "dry run" flag is set), nothing is
  # written and hooks are replaced by a prefixed variant.
  if [[ $p_cwtii_dry_run -eq 1 ]]; then
    u_global_debug
    hook -a 'init' -v 'PROVISION_USING HOST_TYPE INSTANCE_TYPE' -p 'dry_run'
    hook -s 'app instance' -a 'ensure_dirs_exist' -p 'dry_run'
    return
  fi

  u_global_write

  u_make_generate

  # Trigger instance init (optional) extra processes.
  hook -p 'pre' -a 'init'
  hook -a 'init' -v 'PROVISION_USING HOST_TYPE INSTANCE_TYPE'

  # Make sure every writeable folders potentially git-ignored gets created
  # before attempting to (re)set their permissions (see below).
  hook -s 'app instance' -a 'ensure_dirs_exist'

  # (Re)set file system permissions.
  u_instance_set_permissions

  # Trigger post-init (optional) extra processes.
  hook -p 'post' -a 'init'
}

##
# Loads cwt.yml config files (+ variants) and converts them into declarations.
#
# @requires the following variables in calling scope :
# @var yaml_parsed_sp_init
# @var yaml_parsed_globals
#
# @see u_instance_init()
# @see u_instance_yaml_config_parse()
#
# To verify which files can be used (besides ".cwt-local.yml" in this project
# instance's docroot folder $PROJECT_DOCROOT + its variants) and check which one
# will be used - the most specific, run :
# $ hook -s 'instance' \
#   -a 'cwt' \
#   -c 'yml' \
#   -v 'HOST_TYPE INSTANCE_TYPE' \
#   -t -r -d
#
# @example
#   yaml_parsed_sp_init=''
#   yaml_parsed_globals=''
#   u_instance_yaml_config_load
#   # -> Usage 1 - special args override for u_instance_init() :
#   eval "$yaml_parsed_sp_init"
#   echo "$YAML_SERVER_DOCROOT"
#   echo "$YAML_APP_DOCROOT"
#   echo "$YAML_APP_GIT_ORIGIN"
#   # -> Usage 2 - globals declarations :
#   eval "$yaml_parsed_globals"
#
u_instance_yaml_config_load() {
  local instance_yaml_config_file
  local instance_yaml_config_root_files

  # Start by looking for any declarations in CWT dirs (with variants).
  hook_dry_run_matches=''
  hook -s 'instance' -a 'cwt' -c 'yml' -v 'HOST_TYPE INSTANCE_TYPE' -t -r
  for instance_yaml_config_file in $hook_dry_run_matches; do
    u_instance_yaml_config_parse "$instance_yaml_config_file"
  done

  # Now load the local, git-ignored declarations in PROJECT_DOCROOT (so that
  # these take precedence).
  instance_yaml_config_root_files=".cwt-local.yml
.cwt-local.$HOST_TYPE.yml
.cwt-local.$INSTANCE_TYPE.yml
.cwt-local.$HOST_TYPE.$INSTANCE_TYPE.yml"
  for instance_yaml_config_file in $instance_yaml_config_root_files; do
    if [[ -f "$instance_yaml_config_file" ]]; then
      u_instance_yaml_config_parse "$instance_yaml_config_file"
    fi
  done
}

##
# Converts given YAML config file into declarations code (for eval).
#
# Does not support lists for now.
#
# @requires the following variables in calling scope :
# @var yaml_parsed_sp_init
# @var yaml_parsed_globals
#
# @see u_instance_init()
# @see u_instance_yaml_config_load()
#
# For details on the syntax used to determine variable names from the YAML file
# contents :
# @see u_yaml_parse() in cwt/utilities/yaml.sh
#
# @example
#   yaml_parsed_sp_init=''
#   yaml_parsed_globals=''
#   u_instance_yaml_config_parse ./cwt.yml
#   # -> Usage 1 - special args override for u_instance_init() :
#   eval "$yaml_parsed_sp_init"
#   echo "$YAML_SERVER_DOCROOT"
#   echo "$YAML_APP_DOCROOT"
#   echo "$YAML_APP_GIT_ORIGIN"
#   # -> Usage 2 - globals declarations :
#   eval "$yaml_parsed_globals"
#
u_instance_yaml_config_parse() {
  local yaml_config_filepath="$1"
  local parsed_yaml
  local parsed_line
  local parsed_var
  local parsed_var_leaf
  local parsed_val

  if [[ ! -f "$yaml_config_filepath" ]]; then
    echo >&2
    echo "Error in u_instance_yaml_config_parse() - $BASH_SOURCE line $LINENO: given file path '$yaml_config_filepath' does not exist or is not accessible." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    return 1
  fi

  # TODO [evol] support lists (convert to [append] in globals declarations) ?
  while IFS= read -r parsed_line _; do
    parsed_val="$(echo "$parsed_line" | awk -F '[()]' '{print $2}')"
    parsed_var_leaf="=${parsed_line#*=}"
    parsed_var="${parsed_line%$parsed_var_leaf}"
    u_str_uppercase "$parsed_var" 'parsed_var'

    case "$parsed_var" in 'YAML_SERVER_DOCROOT'|'YAML_APP_DOCROOT'|'YAML_APP_GIT_ORIGIN')
      yaml_parsed_sp_init+="$parsed_var=$parsed_val ; "
      continue
    esac

    parsed_var="${parsed_var#'YAML_'}"

    # Debug.
    # echo "parsed_line = '$parsed_line'"
    # echo "parsed_var_leaf = '$parsed_var_leaf'"
    # echo "parsed_var = '$parsed_var'"
    # echo "parsed_val = '$parsed_val'"

    # Trim any ' or " prefix + suffix manually here.
    # parsed_val="${parsed_val%\'}"
    # parsed_val="${parsed_val#\'}"
    # parsed_val="${parsed_val%\"}"
    # parsed_val="${parsed_val#\"}"

    # Escape single quotes in a way that does not break the shell.
    # @link https://stackoverflow.com/a/1250279/2592338
    # parsed_val="${parsed_val//\'/\'\"\'\"\'}"

    yaml_parsed_globals+="global $parsed_var $parsed_val ; "

  done < <(u_yaml_parse "$yaml_config_filepath" 'yaml_')
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
#   make fix-perms
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
#   make fix-ownership
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
# Gets default value for this project instance's domain.
#
# TODO just use the cleaned up local dir name ?
#
# By default, attempt to read local machine IP address. If it's a LAN
# address like 192.168.0.43, the resulting domain will be :
#
# parent-dirname.host-lan-0-43.localhost
#
# @example
#   instance_domain="$(u_instance_domain)"
#   echo "instance_domain = $instance_domain"
#
u_instance_domain() {
  local p_local_host_name="$1"

  if [[ -z "$p_local_host_name" ]]; then
    p_local_host_name="$(u_host_ip)"
  fi

  case "$p_local_host_name" in "192.168."*)
    p_local_host_name="${p_local_host_name//192.168./lan-}"
  esac

  # The dir name is slugified + we remove any '-dev-stack' suffix + lowercase.
  local dirname="${PWD##*/}"
  u_str_sanitize "$dirname" '-' 'dirname'
  dirname="${dirname//-dev-stack/}"
  u_str_lowercase "$dirname" 'dirname'

  if [[ -n "$p_local_host_name" ]]; then
    p_local_host_name="${p_local_host_name//./-}"
    echo "${dirname}.host-${p_local_host_name}.localhost"
    return
  fi

  echo "${dirname}.localhost"
}

##
# [abstract] Sets instance-level registry value.
#
# TODO implement encryption.
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
# TODO implement decryption.
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
