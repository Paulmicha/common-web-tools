#!/usr/bin/env bash

##
# CWT core utility functions.
#
# This file is sourced during core CWT bootstrap.
# @see cwt/bootstrap.sh
#

##
# Initializes primitives (fundamental values for CWT extension mecanisms).
#
# @param 1 [optional] String relative path (defaults to 'cwt' = CWT "core").
#   Provides a extension folder without trailing slash.
# @param 2 [optional] String globals "namespace" (defaults to the uppercase name
#   of the folder passed as 1st arg).
#
# Exports the following "namespaced" global variables, effectively initializing
# all primitives required by hooks - e.g. given p_namespace='CWT' (default value
# of 2nd argument) :
# @export CWT_SUBJECTS (See 1)
# @export CWT_ACTIONS (See 2)
# @export CWT_EXTENSIONS (See 3)
# @export CWT_INC (See 4)
#
# @see hook()
#
# This process uses dotfiles similar to .gitignore (e.g. cwt/.cwt_subjects_ignore).
# they control hooks lookup paths generation. See explanations below.
#
# 1. By default, CWT_SUBJECTS contains the list of depth 1 folders names in ./cwt.
#   If the dotfile '.cwt_subjects' is present in current level, it overrides
#   the entire list and may introduce values that are not folders (see below).
#   If the dotfile '.cwt_subjects_append' exists, its values are added.
#   If the dotfile '.cwt_subjects_ignore' exists, its values are removed from
#     the list of subjects (level 1 folders by default).
#
# 2. CWT_ACTIONS provides a list of *.sh files per subject : for each
#   CWT_SUBJECTS, it will generate values consisting of the file name (without
#   extension, see "Conventions" documentation).
#   The dotfiles '.cwt_actions', '.cwt_actions_append' and '.cwt_actions_ignore'
#   have the same role as the 'subjects' ones described in 1 but must be placed
#   inside relevant subject's folder.
#
# 3. CWT_EXTENSIONS contains a list of all active extensions' folder names. Each
#   one uses the same structure as the 'cwt' folder. The primitive mecanisms
#   explained in 1 & 2 above apply to each one of these extensions.
#   Important notes : extensions' folder names can only contain the following
#   characters : A-Z a-z 0-9 dots . underscores _ dashes -
#   Exception : the name 'extend' is reserved for project-specific
#   implementations.
#
# 4. The 'CWT_INC' values are a simple list of files to be sourced in
#   cwt/bootstrap.sh scope directly. They are meant to contain bash functions
#   organized by subject. E.g. given subject = git : "$p_path/git/git.inc.sh".
#   For convenience, any file matching the scripts/cwt/*.inc.sh pattern will
#   also be added. This gives a place to put some custom project-specific
#   functions that would not necessarily be pertinent in a subject dir.
#
u_cwt_extend() {
  local p_path="$1"
  local p_namespace="$2"

  if [[ -z "$p_path" ]]; then
    p_path='cwt'
  fi

  # Namespace defaults to the "$p_path" sanitized folder name (uppercase).
  if [[ -z "$p_namespace" ]]; then
    u_cwt_extension_namespace "${p_path##*/}" 'p_namespace'
  fi

  # Always reinit as empty strings on every call to u_cwt_extend().
  # @see cwt/test/cwt/hook.test.sh
  export "${p_namespace}_SUBJECTS"=''
  export "${p_namespace}_ACTIONS"=''

  # "Reusable" local var name.
  # @see u_cwt_primitive_values()
  local primitive_values

  # Agregate subjects.
  primitive_values=''
  u_cwt_primitive_values 'subjects' "$p_path"
  local subjects_list="$primitive_values"

  # Agregate remaining primitives.
  local inc
  local action
  local actions_list

  for subject in $subjects_list; do

    # Build up exported subjects list.
    export "${p_namespace}_SUBJECTS"+="$subject "

    # Build up exported generic includes list (by subject).
    inc="$p_path/$subject/${subject}.inc.sh"
    if [[ -f "$inc" ]]; then
      # NB : this must not be namespaced, otherwise extensions' includes wouldn't
      # be loaded during bootstrap.
      CWT_INC+="$inc "
    fi

    primitive_values=''
    u_cwt_primitive_values 'actions' "$p_path/$subject"
    actions_list="$primitive_values"

    for action in $actions_list; do
      # Build up exported actions list (by subject).
      export "${p_namespace}_ACTIONS"+="${subject}/$action "
    done
  done

  # Debug.
  # local subjects_var="${p_namespace}_SUBJECTS"
  # echo "$subjects_var = '${!subjects_var}'"
  # local actions_var="${p_namespace}_ACTIONS"
  # echo "$actions_var = '${!actions_var}'"

  # If extensions are detected, loop through each of them to aggregate namespaced
  # primitives + restrict this to CWT namespace only.
  if [[ "$p_namespace" == 'CWT' ]]; then
    export CWT_EXTENSIONS
    u_cwt_extensions

    # Convenience additional INC lookup for project-specific functions.
    if [[ -d scripts/cwt ]]; then
      for inc in scripts/cwt/*.inc.sh; do
        if [[ -f "$inc" ]]; then
          CWT_INC+="$inc "
        fi
      done
    fi

    # Update 2024-06 cache results.
    # @see cwt/bootstrap.sh
    cwt_primitives_cache_str+="
CWT_INC='$CWT_INC'
CWT_SUBJECTS='$CWT_SUBJECTS'
CWT_ACTIONS='$CWT_ACTIONS'
CWT_EXTENSIONS='$CWT_EXTENSIONS'
"
  else
    local prefixed_subjects_var="${p_namespace}_SUBJECTS"
    local prefixed_actions_var="${p_namespace}_ACTIONS"
    cwt_primitives_cache_str+="
$prefixed_subjects_var='${!prefixed_subjects_var}'
$prefixed_actions_var='${!prefixed_actions_var}'
"
  fi
}

##
# Loads extensions if any exist.
#
# @requires CWT_EXTENSIONS global in calling scope.
# @see u_cwt_extend()
#
u_cwt_extensions() {
  local inc
  local extension
  local exclusions_arr
  local exclusions
  local excl
  local custom_extend_path
  local extensions_ignore_filepath
  local ei_override_lookup_arr
  local ei_override

  # ALlow to deactivate some extensions using dotfile '.cwt_extensions_ignore'.
  # This file can be overridden in project-specific scripts/cwt/override folder.
  exclusions_arr=()
  extensions_ignore_filepath='cwt/extensions/.cwt_extensions_ignore'

  # The following lookups will be used in this order (the last found takes
  # precedence) :
  # - scripts/cwt/override/.cwt_extensions_ignore (convenience default path)
  # - scripts/cwt/override/extensions/.cwt_extensions_ignore (normal override)
  # - scripts/cwt/override/.${PROVISION_USING}.cwt_extensions_ignore
  # - scripts/cwt/override/.${INSTANCE_DOMAIN}.cwt_extensions_ignore
  ei_override_lookup_arr=()
  ei_override_lookup_arr+=('scripts/cwt/override/.cwt_extensions_ignore')
  ei_override_lookup_arr+=('scripts/cwt/override/extensions/.cwt_extensions_ignore')
  if [[ -n "$PROVISION_USING" ]]; then
    ei_override_lookup_arr+=("scripts/cwt/override/.${PROVISION_USING}.cwt_extensions_ignore")
  fi
  if [[ -n "$INSTANCE_DOMAIN" ]]; then
    ei_override_lookup_arr+=("scripts/cwt/override/.${INSTANCE_DOMAIN}.cwt_extensions_ignore")
  fi
  for ei_override in "${ei_override_lookup_arr[@]}"; do
    if [[ -f "$ei_override" ]]; then
      extensions_ignore_filepath="$ei_override"
    fi
  done

  if [[ -f "$extensions_ignore_filepath" ]]; then
    u_fs_get_file_contents "$extensions_ignore_filepath" 'exclusions'
    if [[ -n "$exclusions" ]]; then
      for excl in $exclusions; do
        exclusions_arr+=("$excl")
      done
    fi
  fi

  u_fs_dir_list "cwt/extensions"
  for extension in $dir_list; do

    # Ignore dirnames starting with '.'.
    if [[ "${extension:0:1}" == '.' ]]; then
      continue
    fi

    # Exclusions check.
    if u_in_array "$extension" exclusions_arr; then
      continue
    fi

    CWT_EXTENSIONS+="$extension "

    # Aggregate namespaced primitives for every extension.
    u_cwt_extend "cwt/extensions/$extension"

    # For convenience, also accept generic includes at the root of extensions.
    inc="cwt/extensions/$extension/${extension}.inc.sh"
    if [[ -f "$inc" ]]; then
      CWT_INC+="$inc "
    fi
  done

  # Consider "scripts/cwt/extend" as an extension. This allows to
  # provide any implementation like "normal" CWT extensions meant for current
  # project-specific operations (non-reusable).
  custom_extend_path="scripts/cwt/extend"
  if [[ -d "$custom_extend_path" ]]; then
    CWT_EXTENSIONS+="extend "
    u_cwt_extend "$custom_extend_path"
    inc="$custom_extend_path/extend.inc.sh"
    if [[ -f "$inc" ]]; then
      CWT_INC+="$inc "
    fi
  fi
}

##
# Get extension path by name.
#
# @requires local var $ext_path in calling scope.
# This function modifies an existing variable for performance reasons (in order
# to avoid using a subshell).
#
# @example
#   ext_path=''
#   u_cwt_extension_path 'extend'
#   echo "$ext_path" # Yields 'scripts/cwt'
#
u_cwt_extension_path() {
  ext_path='cwt/extensions'
  case "$1" in 'extend')
    ext_path='scripts/cwt'
  esac
}

##
# Provides primitive values for given path.
#
# @requires local var $primitive_values in calling scope.
# This function modifies an existing variable for performance reasons (in order
# to avoid using a subshell).
#
# @param 1 String which primitive values to get (lowercase).
# @param 2 [optional] String relative path (defaults to 'cwt' = CWT "core").
#   Provides a extension folder without trailing slash.
# @param 3 [optional] String an 'action' value.
#
# Dotfiles MUST contain a list of words without any special characters nor
# spaces. The values provided will determine dynamic includes lookup paths :
# @see u_cwt_extend()
#
# @example
#   primitive_values=''
#   u_cwt_primitive_values 'subjects'
#   echo "$primitive_values" # Yields 'app  cache  git  host  instance  make  test'
#
#   # Default path 'cwt' can be modified by providing the 2nd argument :
#   primitive_values=''
#   u_cwt_primitive_values 'actions' 'path/to/extension/folder'
#   echo "$primitive_values"
#
u_cwt_primitive_values() {
  local p_primitive="$1"
  local p_path="$2"
  local p_action="$3"

  if [[ -z "$p_path" ]]; then
    p_path='cwt'
  fi

  local dotfile
  local dotfile_contents

  # For prefixes and variants primitives, hardcoded default values are used
  # during the generation of lookup paths unless specific dotfiles per action
  # exist. This extra dotfile (per action) does not cancel out the base dotfile
  # (per subject) - its values are simply added if both exist.
  local dn
  local dotfile_names='cwt'
  # case "$p_primitive" in variants|prefixes)
  if [[ -n "$p_action" ]]; then
    dotfile_names+=" cwt_$p_action"
  fi
  # esac

  # Look for the dotfile that provides explictly ignored values.
  local ignored_values=()
  local ignored_val
  for dn in $dotfile_names; do
    dotfile="$p_path/.${dn}_${p_primitive}_ignore"
    if [[ -f "$dotfile" ]]; then
      u_fs_get_file_contents "$dotfile" 'dotfile_contents'
      if [[ -n "$dotfile_contents" ]]; then
        for ignored_val in $dotfile_contents; do
          ignored_values+=("$ignored_val")
        done
      fi
    fi
  done

  # Look for the dotfile that will override all default values.
  local proceed=1
  for dn in $dotfile_names; do
    dotfile="$p_path/.${dn}_${p_primitive}"
    if [[ -f "$dotfile" ]]; then
      proceed=0
      u_fs_get_file_contents "$dotfile" 'dotfile_contents'
      if [[ -n "$dotfile_contents" ]]; then
        primitive_values="$dotfile_contents"
      fi
    fi
  done

  # Provide dynamic default values.
  if [[ $proceed -eq 1 ]]; then
    local dyn_values
    case "$p_primitive" in
      subjects)
        u_fs_dir_list "$p_path"
        dyn_values=$dir_list
      ;;
      actions)
        u_fs_file_list "$p_path"
        dyn_values=$file_list
      ;;
    esac

    # Filter out invalid values.
    local v
    local v_dots_arr
    for v in $dyn_values; do

      # Always ignore values starting with a dot.
      if [[ "${v:0:1}" == '.' ]]; then
        continue
      fi

      # Leave out any value explicitly ignored via dotfile.
      if u_in_array "$v" 'ignored_values'; then
        continue
      fi

      # Actions need to remove *.sh extension + ignore files using any double
      # extension pattern.
      if [[ "$p_primitive" == 'actions' ]]; then
        v="${v%%.sh}"
        u_str_split1 'v_dots_arr' "$v" '.'

        if [[ ${#v_dots_arr[@]} -gt 1 ]]; then
          continue
        fi
      fi

      primitive_values+=" $v "
    done
  fi

  # Look for the dotfile that provides additional values + add them if it exists.
  for dn in $dotfile_names; do
    dotfile="$p_path/.${dn}_${p_primitive}_append"
    if [[ -f "$dotfile" ]]; then
      u_fs_get_file_contents "$dotfile" 'dotfile_contents'
      if [[ -n "$dotfile_contents" ]]; then
        local added_val
        for added_val in $dotfile_contents; do
          primitive_values+=" $added_val "
        done
      fi
    fi
  done
}

##
# Gets a CWT extension namespace.
#
# @param 1 String : extension folder name or path.
# @param 2 [optional] String : the variable name in calling scope which will be
#   assigned the result. Defaults to 'extension_namespace'.
#
# @var [default] extension_namespace
#
# @example
#   u_cwt_extension_namespace "cwt/extensions/docker-compose"
#   echo "$extension_namespace" # <- Prints DOCKER_COMPOSE.
#
#   # Using a custom variable name :
#   my_ns_var=""
#   for extension in $CWT_EXTENSIONS; do
#     u_cwt_extension_namespace "$extension" 'my_ns_var'
#     echo "$my_ns_var"
#   done
#
u_cwt_extension_namespace() {
  local p_ext="$1"
  local p_cwt_ext_ns_var_name="$2"
  local cwt_ext_ns_result

  if [[ -z "$p_cwt_ext_ns_var_name" ]]; then
    p_cwt_ext_ns_var_name='extension_namespace'
  fi

  cwt_ext_ns_result="${p_ext##*/}"
  u_str_sanitize_var_name "$cwt_ext_ns_result" 'cwt_ext_ns_result'
  u_str_uppercase "$cwt_ext_ns_result" 'cwt_ext_ns_result'

  printf -v "$p_cwt_ext_ns_var_name" '%s' "$cwt_ext_ns_result"
}

##
# Checks if a namespace has given subject.
#
# @param 1 String : extension path (or folder name).
# @param 2 String : the subject to check against.
#
# @example
#   for extension in $CWT_EXTENSIONS; do
#     if u_cwt_namespace_has_subject "cwt/extensions/$extension" 'db' ; then
#       echo "extension '$extension' has the 'db' subject"
#     fi
#   done
#
u_cwt_namespace_has_subject() {
  local p_extension_path="$1"
  local p_subject="$2"

  local extension_subjects
  local extension_subjects_var
  local extension_namespace

  u_cwt_extension_namespace "$p_extension_path"
  extension_subjects_var="${extension_namespace}_SUBJECTS"
  extension_subjects="${!extension_subjects_var}"

  if [[ -n "$extension_subjects" ]]; then
    local s
    for s in $extension_subjects; do
      case "$p_subject" in "$s")
        return
      esac
    done
  fi

  false
}

##
# Gets all actions + their script path defined in current project instance.
#
# NB : for performance reasons (to avoid using a subshell), this function
# writes its result to variables subject to collision in calling scope.
#
# @var cwt_action_names
# @var cwt_action_scripts
#
# @example
#   u_cwt_get_actions
#   # Check result (names) :
#   declare -p cwt_action_names
#   # -> output (names) :
#   #   declare -a cwt_action_names='([0]="app/compile" [1]="app/git" ...)'
#   # Check result (script files path) :
#   for f in "${cwt_action_scripts[@]}"; do
#     echo "$f"
#   done
#
# @example (sorted)
#   u_cwt_get_actions
#   u_array_qsort "${cwt_action_names[@]}"
#   u_array_print sorted_arr
#
u_cwt_get_actions() {
  local subjects="$CWT_SUBJECTS"
  local actions="$CWT_ACTIONS"
  local extensions="$CWT_EXTENSIONS"
  local base_paths=("cwt")

  local a
  local s
  local bp
  local extension
  local uppercase
  local ext_path
  local subjects_var
  local actions_var

  cwt_action_names=()
  cwt_action_scripts=()

  for extension in $extensions; do
    uppercase="$extension"
    u_str_sanitize_var_name "$uppercase" 'uppercase'
    u_str_uppercase "$uppercase"
    subjects_var="${uppercase}_SUBJECTS"
    subjects+=" ${!subjects_var}"
    actions_var="${uppercase}_ACTIONS"
    actions+=" ${!actions_var}"
    ext_path=''
    u_cwt_extension_path "$extension"
    base_paths+=("$ext_path/$extension")
  done

  for s in $subjects; do
    for bp in "${base_paths[@]}"; do
      if ! u_cwt_namespace_has_subject "$bp" "$s" ; then
        continue
      fi
      for a in $actions; do
        case "$a" in "$s"*)
          lookup_path="$bp/${a}.sh"
          if [[ -f "$lookup_path" ]]; then
            if ! u_in_array $lookup_path cwt_action_scripts; then
              cwt_action_names+=("$a")
              cwt_action_scripts+=("$lookup_path")
            fi
          fi
        esac
      done
    done
  done
}

##
# Prints a list of Makefiles includes.
#
# The default location is a file called 'make.mk' inside the extension folder.
# This function merely lists these locations (separated by a space) for each
# currently active extensions.
#
# @example
#   lookup_paths="$(u_cwt_extensions_get_makefiles)"
#   echo "$lookup_paths"
#
u_cwt_extensions_get_makefiles() {
  local mk_includes_lp=''
  local cwt_gm_ext=''
  local ext_path=''

  for cwt_gm_ext in $CWT_EXTENSIONS; do
    ext_path=''
    u_cwt_extension_path "$cwt_gm_ext"
    mk_includes_lp+="$ext_path/$cwt_gm_ext/make.mk "
  done

  echo "$mk_includes_lp"
}

##
# Tests if an extension is exists and is enabled.
#
# @param 1 String : the extension (folder) name.
#
# @example
#   ext='db'
#   if u_cwt_extension_exists "$ext"; then
#     echo "The '$ext' extension exists and is enabled"
#   else
#     echo "The '$ext' extension is not enabled or doesn't exist"
#   fi
#
u_cwt_extension_exists() {
  case "$CWT_EXTENSIONS" in *" $1 "*|"$1 "*)
    return 0
  esac
  return 1
}
