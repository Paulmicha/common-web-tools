#!/usr/bin/env bash

##
# CWT internals related utility functions.
#
# This file is dynamically loaded.
# @see cwt/bootstrap.sh
#

##
# Initializes primitives (fundamental values for CWT extension mecanisms).
#
# TODO evaluate merging base 'path' and 'namespace' options.
#
# This process uses dotfiles similar to .gitignore (e.g. cwt/.cwt_subjects) :
# they control which files are included (sourced) during "bootstrap" depending
# on current local instance's CWT_STATE (e.g. installed, initialized, running).
#
# @param 1 [optional] String relative path (defaults to './cwt' = CWT "core").
# @param 2 [optional] String globals "namespace" (defaults to the uppercase name
#   of the folder passed as 1st arg).
#
# Exports "namespaced" globals prefixed by 'CWT' or optional 2nd argument.
# E.g. given global NAMESPACE='CWT' :
# @export CWT_SUBJECTS (See 1)
# @export CWT_ACTIONS (See 2.1)
# @export CWT_PREFIXES (See 2.2)
# @export CWT_VARIANTS (See 2.3)
# @export CWT_PRESETS (See 3)
#
# 1. By default, contains the list of depth 1 folders names in ./cwt (w/o slashes).
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
#     By default, all actions are allocated the following variants :
#     - PROVISION_USING
#     - INSTANCE_TYPE
#     - HOST_TYPE
#     The previous naming + dotfile pattern applies (see 2.1), with an
#     additional one for altering defaults : '.cwt_variants_alter'.
#
# 3. This only applies AFTER stack init has been run once if the global env var
#   CWT_CUSTOM_DIR was assigned a different value than 'cwt/custom'.
#   It contains a list of folders containing the exact same structure as 'cwt'.
#   Every extension mecanism explained in 1 & 2 above applies to each preset.
#
# @see "conventions" + "extensibility" documentation.
#
u_cwt_extend() {
  local p_path="$1"
  local p_namespace="$2"

  if [[ -z "$p_path" ]]; then
    p_path='cwt'
  fi

  if [[ -z "$p_namespace" ]]; then
    uppercase="${p_path##*/}"
    u_str_uppercase
    p_namespace="$uppercase"
  fi

  local primitives="SUBJECTS ACTIONS PREFIXES VARIANTS PRESETS"
  local prim
  local uppercase

  for prim in $primitives; do
    eval "export ${p_namespace}_${prim}"
  done

  # By default, subjects are the list of depth 1 folders in given path.
  local subject
  local subjects_list
  local subjects_ignore

  subjects_list="$(u_cwt_read 'subjects' "$p_path")"
  if [[ -z "$subjects_list" ]]; then
    subjects_list=$(u_fs_dir_list "$p_path")
  fi

  subjects_ignore="$(u_cwt_read 'subjects_ignore' "$p_path")"
  if [[ -z "$subjects_ignore" ]]; then
    subjects_list=$(u_fs_dir_list "$p_path")
  fi

  # echo
  # echo "  subjects_list = $subjects_list"
  # echo

  local action
  local actions_list
  local inc
  local file
  local file_list
  local file_wodots
  local diff
  local file_contents
  local added_val

  for subject in $subjects_list; do

    # Ignore dirnames starting with '.'.
    if [[ "${subject:0:1}" == '.' ]]; then
      continue
    fi

    # Start "group" with subject = the containing folder.
    eval "${p_namespace}_SUBJECTS+=\"$subject \""

    # Ignore subjects that do NOT have a dedicated folder (e.g. meant for
    # function-based hooks only).
    if [[ ! -d "$p_path/$subject" ]]; then
      continue
    fi

    action=''
    actions_list=''
    inc=''
    file=''
    file_list=''
    file_wodots=''
    diff=0

    # It's possible to provide a dotfile bypassing entirely the default file
    # enumeration process below.
    actions_list="$(u_cwt_read 'actions' "$p_path/$subject")"

    if [[ -n "$actions_list" ]]; then
      for action in $actions_list; do
        eval "${p_namespace}_ACTIONS+=\"${subject}:$action \""
      done

    # Default actions are all *.sh files NOT using multiple extension pattern in
    # that dir (also excludes "dotfiles" - file names starting with '.').
    else
      file_list=$(u_fs_file_list "$p_path/$subject")
      for file in $file_list; do
        # Ignore dotfiles.
        if [[ "${file:0:1}" == '.' ]]; then
          continue
        fi
        # Cut off *.sh extension.
        file="${file%%.sh}"
        # Skip filenames using mutliple extension.
        file_wodots="${file//\.}"
        if (( ${#file} - ${#file_wodots} > 0 )); then
          continue
        fi
        eval "${p_namespace}_ACTIONS+=\"${subject}:$file \""
      done
    fi

    # The 'INC' values are a simple list of files to be sourced in
    # cwt/bootstrap.sh scope directly. They are meant to contain bash functions.
    inc="$p_path/$subject/${subject}.inc.sh"
    if [[ -f "$inc" ]]; then
      eval "${p_namespace}_INC+=\"$inc \""
    fi

    # The remaining primitives share the same processing.
    eval "${p_namespace}_PREFIXES=\"pre post\""
    eval "${p_namespace}_VARIANTS=\"PROVISION_USING INSTANCE_TYPE HOST_TYPE\""
    primitives="prefixes variants"

    for prim in $primitives; do
      uppercase="$prim"
      u_str_uppercase

      # Look for the dotfile that will override all default values.
      file="$p_path/$subject/.${subject}_${prim}"

      if [[ -f "$file" ]]; then
        file_contents=$(< "$file")

        if [[ -n "$file_contents" ]]; then
          added_val=''

          for added_val in $file_contents; do
            eval "${p_namespace}_${uppercase}+=\"${subject}:$added_val \""
          done
        fi
      fi

      # Look for the dotfile that provides additional values.
      file="$p_path/$subject/.${subject}_${prim}_append"

      if [[ -f "$file" ]]; then
        file_contents=$(< "$file")

        if [[ -n "$file_contents" ]]; then
          added_val=''

          for added_val in $file_contents; do
            eval "${p_namespace}_${uppercase}+=\"${subject}:$added_val \""
          done
        fi
      fi
    done
  done

  # If presets are detected, loop through each of them to aggregate namespaced
  # primitives.
  # Restrict this to CWT namespace only.
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
# Returns primitive values for given path.
#
# @param 1 String which primitive values to get.
# @param 2 [optional] String relative path (defaults to 'cwt' = CWT "core").
#
# Dotfiles MUST contain a list of words without any special characters nor
# spaces. The values provided will determine dynamic includes lookup paths :
# @see u_cwt_extend()
#
# @example
#   subjects="$(u_cwt_read subjects_ignore)"
#   echo "$subjects" # Yields 'utilities'
#
#   # Default path 'cwt' can be modified by providing the 2nd argument :
#   subjects="$(u_cwt_read subjects_ignore 'path/to/relative/dir')"
#   echo "$subjects"
#
u_cwt_read() {
  local p_suffix="$1"
  local p_path="$2"

  local uppercase="$p_suffix"
  u_str_uppercase

  local dotfile="$p_path/.cwt_${p_suffix}"
  local file_contents

  # Allow overrides.
  local override_file=''
  eval $(u_autoload_override "$dotfile" '' 'override_file="$override"')
  if [[ -n "$override_file" ]]; then
    cat "$override_file"
    return 0
  fi

  # Allow complements.
  local complement_filepath=$(u_autoload_get_complement "$dotfile" 'get_complement_filepath')
  if [[ -n "$complement_filepath" ]]; then
    cat "$complement_filepath"
  fi

  # Finally, output the normal "$p_path/.cwt_${p_suffix}" file contents (if it
  # exists).
  if [[ -f "$dotfile" ]]; then
    cat "$dotfile"
  fi
}
