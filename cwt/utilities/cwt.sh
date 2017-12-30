#!/usr/bin/env bash

##
# CWT core utility functions.
#
# TODO refacto 'stack' into 2 different subjects : 'instance' + 'service'.
#
# This file is dynamically loaded.
# @see cwt/bootstrap.sh
#

##
# Initializes primitives (fundamental values for CWT extension mecanisms).
#
# TODO evaluate merging base 'path' and 'namespace' options.
# TODO implement local instance's CWT_STATE (e.g. installed, initialized, running).
#
# @param 1 [optional] String relative path (defaults to 'cwt' = CWT "core").
#   Provides a preset folder without trailing slash.
# @param 2 [optional] String globals "namespace" (defaults to the uppercase name
#   of the folder passed as 1st arg).
#
# Exports the following "namespaced" global variables, effectively initializing
# all primitives required by hooks - e.g. given p_namespace='CWT' (default value
# of 2nd argument) :
# @export CWT_SUBJECTS (See 1)
# @export CWT_ACTIONS (See 2.1)
# @export CWT_PREFIXES (See 2.2)
# @export CWT_VARIANTS (See 2.3)
# @export CWT_PRESETS (See 3)
# @export CWT_INC (See 4)
#
# @see hook()
#
# This process uses dotfiles similar to .gitignore (e.g. cwt/.cwt_subjects_ignore).
# they control hooks lookup paths generation. See explanations below.
#
# 1. By default, contains the list of depth 1 folders names in ./cwt.
#   If the dotfile '.cwt_subjects' is present in current level, it overrides
#   the entire list and may introduce values that are not folders (see below).
#   If the dotfile '.cwt_subjects_append' exists, its values are added.
#   If the dotfile '.cwt_subjects_ignore' exists, its values are removed from
#     the list of subjects (level 1 folders by default).
#
# 2. These variables determine how to look for files to include during hooks
#   (events) PER SUBJECT. Here's an example, given subject='stack' :
#
#   - 2.1 actions : provide list of all *.sh files in 'cwt/stack' by default (no
#     extension - values are only the 'name' of the file, see Conventions doc).
#     The dotfiles '.cwt_actions' and '.cwt_actions_append' have the same role
#     as the 'subjects' ones described in 1 but must be placed inside 'cwt/stack'.
#
#   - 2.2 prefixes : 'pre' + 'post' are provided by default for all actions.
#     The previous dotfile pattern applies (see 2.1).
#
#   - 2.3 variants : declare how to look for files to include in hooks (events)
#     PER ACTION (by subject and/or preset). They define which global variables
#     are used during lookup paths generation process, and which separator is
#     used for concatenation.
#     By default, all actions are assigned the following variants :
#     - PROVISION_USING
#     - INSTANCE_TYPE
#     - HOST_TYPE
#     The previous naming + dotfile pattern applies (see 2.1).
#
# 3. This only applies AFTER stack init has been run once if the global env var
#   CWT_CUSTOM_DIR was assigned a different value than 'cwt/custom'.
#   It contains a list of folders containing the exact same structure as 'cwt'.
#   Every extension mecanism explained in 1 & 2 above applies to each preset.
#
# 4. The 'CWT_INC' values are a simple list of files to be sourced in
#   cwt/bootstrap.sh scope directly. They are meant to contain bash functions
#   organized by subject.
#
# @see "conventions" + "extensibility" documentation.
#
u_cwt_extend() {
  local p_path="$1"
  local p_namespace="$2"

  if [[ -z "$p_path" ]]; then
    p_path='cwt'
  fi

  # Namespace defaults to the "$p_path" folder name (uppercase).
  local uppercase
  if [[ -z "$p_namespace" ]]; then
    uppercase="${p_path##*/}"
    u_str_uppercase
    p_namespace="$uppercase"
  fi

  # Export initial global variables for every primitive + always reinit as empty
  # strings on every call to u_cwt_extend().
  local primitives='SUBJECTS ACTIONS PREFIXES VARIANTS PRESETS'
  local prim
  for prim in $primitives; do
    eval "export ${p_namespace}_${prim}=''"
  done

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
  local prefix
  local prefixes_list
  local variant
  local variants_list

  for subject in $subjects_list; do

    # Build up exported subjects list.
    eval "${p_namespace}_SUBJECTS+=\"$subject \""

    # Build up exported generic includes list (by subject).
    inc="$p_path/$subject/${subject}.inc.sh"
    if [[ -f "$inc" ]]; then
      eval "${p_namespace}_INC+=\"$inc \""
    fi

    primitive_values=''
    u_cwt_primitive_values 'actions' "$p_path/$subject"
    actions_list="$primitive_values"

    for action in $actions_list; do

      # Build up exported actions list (by subject).
      eval "${p_namespace}_ACTIONS+=\"${subject}:$action \""

      # Build up exported prefixes (by subject AND by action).
      # TODO : progressively fallback unless explicitly specified ?
      primitive_values=''
      u_cwt_primitive_values 'prefixes' "$p_path/$subject"
      prefixes_list="$primitive_values"
      for prefix in $prefixes_list; do
        eval "${p_namespace}_PREFIXES+=\"${subject}:$action:$prefix \""
      done

      # Build up exported variants (by subject AND by action).
      # TODO : progressively fallback unless explicitly specified ?
      primitive_values=''
      u_cwt_primitive_values 'variants' "$p_path/$subject"
      variants_list="$primitive_values"
      for variant in $variants_list; do
        eval "${p_namespace}_VARIANTS+=\"${subject}:$action:$variant \""
      done
    done
  done

  # If presets are detected, loop through each of them to aggregate namespaced
  # primitives + restrict this to CWT namespace only.
  if [[ "$p_namespace" == 'CWT' ]]; then
    export CWT_PRESETS
    u_cwt_presets
  fi
}

##
# Loads presets if any exist.
#
# @requires CWT_PRESETS global in calling scope.
# @see u_cwt_extend()
#
u_cwt_presets() {
  local presets_dir="cwt/custom"
  if [[ -n "$CWT_CUSTOM_DIR" ]]; then
    presets_dir="$CWT_CUSTOM_DIR"
  fi

  local preset
  local presets_list=$(u_fs_dir_list "$presets_dir")

  for preset in $presets_list; do

    # Ignore dirnames starting with '.'.
    if [[ "${preset:0:1}" == '.' ]]; then
      continue
    fi

    # Ignore reserved dirnames 'complements' and 'overrides'.
    # @see cwt/custom/README.md
    if [[ ("$preset" == 'complements') || ("$preset" == 'overrides') ]]; then
      continue
    fi

    eval "CWT_PRESETS+=\"$preset \""

    # Aggregate namespaced primitives for every preset.
    u_cwt_extend "$presets_dir/$preset"
  done
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
#   Provides a preset folder without trailing slash.
#
# Dotfiles MUST contain a list of words without any special characters nor
# spaces. The values provided will determine dynamic includes lookup paths :
# @see u_cwt_extend()
#
# @example
#   primitive_values=''
#   u_cwt_primitive_values 'subjects'
#   echo "$primitive_values" # Yields 'app cron db env git provision remote stack test'
#
#   # Default path 'cwt' can be modified by providing the 2nd argument :
#   primitive_values=''
#   u_cwt_primitive_values 'actions' 'path/to/preset/folder'
#   echo "$primitive_values"
#
u_cwt_primitive_values() {
  local p_primitive="$1"
  local p_path="$2"

  if [[ -z "$p_path" ]]; then
    p_path='cwt'
  fi

  local dotfile
  local dotfile_contents

  # Provide hardcoded default values.
  case "$p_primitive" in
    prefixes) primitive_values='pre post' ;;
    variants) primitive_values='PROVISION_USING INSTANCE_TYPE HOST_TYPE' ;;
  esac

  # Look for the dotfile that provides explictly ignored values.
  local ignored_values=()
  local ignored_val
  dotfile="$p_path/.cwt_${p_primitive}_ignore"
  if [[ -f "$dotfile" ]]; then
    dotfile_contents=$(< "$dotfile")
    if [[ -n "$dotfile_contents" ]]; then
      for ignored_val in $dotfile_contents; do
        ignored_values+=("$ignored_val")
      done
    fi
  fi

  # Look for the dotfile that will override all default values.
  dotfile="$p_path/.cwt_${p_primitive}"
  if [[ -f "$dotfile" ]]; then
    dotfile_contents=$(< "$dotfile")
    if [[ -n "$dotfile_contents" ]]; then
      primitive_values="$dotfile_contents"
    fi

  # Provide dynamic default values.
  else
    local dyn_values
    case "$p_primitive" in
      subjects)
        dyn_values=$(u_fs_dir_list "$p_path")
      ;;
      actions)
        dyn_values=$(u_fs_file_list "$p_path")
      ;;
    esac

    # Filter out invalid values.
    # TODO should we forbid / sanitize unexpected characters (space, *, etc.) ?
    local v
    local v_wodots
    for v in $dyn_values; do

      # Always ignore values starting with a dot.
      if [[ "${v:0:1}" == '.' ]]; then
        continue
      fi

      # Leave out any value explicitly ignored via dotfile.
      if u_in_array "$v" ignored_values; then
        continue
      fi

      # Actions need to remove *.sh extension + ignore files using any double
      # extension pattern.
      if [[ "$p_primitive" == 'actions' ]]; then
        v="${v%%.sh}"
        v_wodots="${v//\.}"
        if (( ${#v} - ${#v_wodots} > 0 )); then
          continue
        fi
      fi

      primitive_values+=" $v "
    done
  fi

  # Look for the dotfile that provides additional values + add them if it exists.
  dotfile="$p_path/.cwt_${p_primitive}_append"
  if [[ -f "$dotfile" ]]; then
    dotfile_contents=$(< "$dotfile")
    if [[ -n "$dotfile_contents" ]]; then
      local added_val
      for added_val in $dotfile_contents; do
        primitive_values+=" $added_val "
      done
    fi
  fi
}
