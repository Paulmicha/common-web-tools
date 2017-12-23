#!/usr/bin/env bash

##
# CWT internals related utility functions.
#
# This file is dynamically loaded.
# @see cwt/bootstrap.sh
#

##
# Initializes hooks and lookups (CWT extension mecanisms).
#
# This process uses dotfiles similar to .gitignore (e.g. cwt/.cwt_subjects) :
# they control which files are included (sourced) during "bootstrap" depending
# on current local instance's CWT_STATE (e.g. installed, initialized, running).
#
# @param 1 [optional] String relative path (defaults to './cwt' = CWT "core").
# @param 2 [optional] String globals "namespace" (defaults to 'CWT').
#
# Exports "namespaced" globals prefixed by 'CWT' or optional 2nd argument.
# E.g. given global NAMESPACE='CWT' :
# @export CWT_SUBJECTS (var name semi-hardcoded. See 1)
# @export CWT_ACTIONS (generated var name 1. See 2)
# @export CWT_VARIANTS (generated var name 2. See 2)
# @export CWT_PREFIX_SUFFIX (generated var name 3. See 2)
# @export CWT_... (generated var name n. See 3)
#
# 1. By default, contains the list of depth 1 folders names in ./cwt (w/o slashes).
#   If the dotfile '.cwt_subjects' is present in current level, it overrides
#   the entire list and may introduce values that are not folders (see below).
#   If the dotfile '.cwt_subjects.append' exists, its values are added.
#
# 2. These variables names are based on the default cwt/.cwt_extensions file.
#   They declare how to look for files to include in hooks (events) PER SUBJECT.
#   Here's an example, given subject='stack' :
#
#   - 2.1 actions : provide list of all *.sh files in 'cwt/stack' by default (no
#     extension - values are only the 'name' of the file, see Conventions doc).
#     The dotfiles '.cwt_actions' and '.cwt_actions.append' have the same role
#     as the 'subjects' ones described in 1 but must be placed inside 'cwt/stack'.
#     NB : the term 'actions' is the first declared in the default
#     cwt/.cwt_extensions file. If a preset provides another term, the mecanism
#     is the same - it will impact the generation of lookup paths.
#
#   - 2.2 variants : declare how to look for files to include in hooks (events)
#     PER ACTION (by subject). They define which global variables are used
#     (and how - e.g. separator, position) in lookup paths PER ACTION.
#     The previous naming + dotfile pattern applies (see 2.1).
#
#   - 2.3 prefix_suffix : 'pre' + 'post' are provided by default for all actions.
#     The previous naming + dotfile pattern applies (see 2.1).
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
    # TODO [dx] Should this default to the uppercase name of the relative folder ?
    p_namespace='CWT'
  fi

  # Multiple extensions pattern : export as "namespace"-prefixed globals.
  local ext
  local extensions="$(u_cwt_get 'extensions' 'words' "$p_path" "$p_namespace")"

  # echo
  # echo "  extensions = $extensions"
  # echo

  # See https://stackoverflow.com/a/7950330 for the herestring '<<<' operator.
  local extensions_uppercase=$(tr '[a-z]' '[A-Z]' <<< $extensions)

  for ext in $extensions_uppercase; do
    eval "export ${p_namespace}_${ext}"
  done

  local subject=''
  local subjects_list=''
  local uppercase=''

  subjects_list="$(u_cwt_get 'subjects' 'words' "$p_path" "$p_namespace")"

  # echo
  # echo "  subjects_list = $subjects_list"
  # echo

  local inc
  local file
  local file_list
  local file_wodots
  local diff

  for subject in $subjects_list; do

    # Ignore dirnames starting with '.'.
    if [[ "${subject:0:1}" == '.' ]]; then
      continue
    fi

    # Ignore subjects that do NOT have a dedicated folder (e.g. meant for
    # function-based hooks only).
    if [[ ! -d "$p_path/$subject" ]]; then
      eval "${p_namespace}_SUBJECTS+=\"$subject \""
      continue
    fi

    inc=''
    file=''
    file_list=''
    file_wodots=''
    diff=0

    # Start "group" with subject = the containing folder.
    eval "${p_namespace}_SUBJECTS+=\"$subject \""

    # Default actions are all *.sh files NOT using multiple extension pattern in
    # that dir (also excludes "dotfiles" - file names starting with '.').
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

    # The 'INC' extensions are a simple list of files to be sourced in
    # cwt/bootstrap.sh scope directly (as it contains bash functions).
    # -> no need to use "kss" string storage.
    inc="$p_path/$subject/${subject}.inc.sh"
    if [[ -f "$inc" ]]; then
      eval "${p_namespace}_INC+=\"$inc \""
    fi

    # For all the other cases : files contents must be read to add values to
    # the corresponding CWT globals.
    for ext in $extensions; do
      # These are similar to .gitignore files : they whitelist CWT extensions.
      file="$p_path/$subject/.${subject}_${ext}"

      if [[ -f "$file" ]]; then
        local file_contents=$(<"$file")
        uppercase=$(tr '[a-z]' '[A-Z]' <<< $ext)

        if [[ -n "$file_contents" ]]; then
          local added_val=''

          for added_val in $file_contents; do
            eval "${p_namespace}_${uppercase}+=\"${subject}:$added_val \""
          done
        fi
      fi
    done
  done

  # Post-process initial bootstrap phase : resolve and combinations.
  # u_cwt_extend_combinations
}

##
# TODO [wip] Makes a 2nd pass to provide object combinations.
#
# u_cwt_extend_combinations() {
#   # Always add these 2 default variants for every action.
#   # if [[ "$ext" == 'actions' ]]; then
#   #   eval "$(u_string_kss_write CWT_VARIANTS "pre_$added_val" "$p_path/$dir")"
#   #   eval "$(u_string_kss_write CWT_VARIANTS "post_$added_val" "$p_path/$dir")"
#   # fi
# }

##
# [internal] Basic CWT getter function (maps functions by given value name).
#
# NB : does not check if resulting function name is defined before calling it.
#
# @param 1 String name of the value(s) to get - i.e. for what extension.
# @param 2 String type of value to get (determines lookup processing).
# @param n+2 the rest of the arguments are forwarded to dynamic function name.
#
# @example
#   extensions="$(u_cwt_get extensions words 'path/to/relative/dir')"
#   echo "$extensions"
#   # @see u_cwt_get_extending_words()
#
u_cwt_get() {
  local p_which_values="$1"
  local p_type="$2"
  shift 2

  case "$p_type" in

    # These values are meant for the same ".gitignore"-like lookup pattern.
    # @see u_cwt_get_extending_words()
    words)
      echo "$(u_cwt_get_extending_words $p_which_values $@)"
    ;;

    # Default : attempt to call the function name "u_cwt_$p_which_values".
    *)
      echo "$(u_cwt_$p_which_values $@)"
    ;;
  esac
}

##
# Returns a list of words read from ".gitignore"-like files.
#
# These can be listed either 1 per line or in a single space-separated string.
#
# Determines dynamic includes lookup paths using file naming conventions used to
# export "namespaced" globals (prefixed by optional 2nd argument).
# @see "conventions" + "extensibility" documentation.
# @see u_cwt_extend()
#
# TODO explore possibility of prefix + suffix (delimited by dot ?) + namespace
# variations in words for adding different ways to extend / alter CWT.
#
# @param 1 [optional] String relative path (defaults to './cwt' = CWT "core").
# @param 2 [optional] String globals "namespace" (defaults to 'CWT').
#
# @example
#   # Example with subjects.
#   words="$(u_cwt_get_extending_words subjects 'path/to/relative/dir' 'MY_NAMESPACE')"
#   echo "$words"
#   # Yields for ex. "app db env git provision remote stack test instance"
#
#   # Example with extensions.
#   words="$(u_cwt_get_extending_words extensions 'path/to/relative/dir' 'MY_NAMESPACE')"
#   echo "$words"
#   # Yields for ex. "predicates actions variants combos"
#
u_cwt_get_extending_words() {
  local p_suffix="$1"
  local p_path="$2"
  local p_namespace="$3"

  local uppercase=$(tr '[a-z]' '[A-Z]' <<< $p_suffix)

  local ext
  local words_list_file="$p_path/.cwt_${p_suffix}"
  local file_contents

  # Allow overrides.
  local override_file=''
  eval $(u_autoload_override "$words_list_file" '' 'override_file="$override"')
  if [[ -n "$override_file" ]]; then
    echo "$(< "$override_file")"
    return 0
  fi

  # Allow complements.
  local complement_filepath=$(u_autoload_get_complement "$words_list_file" 'get_complement_filepath')
  if [[ -n "$complement_filepath" ]]; then
    echo "$(< "$complement_filepath")"
  fi

  # Finally, output the normal "$p_path/.cwt_${p_suffix}" file contents (if it
  # exists).
  if [[ -f "$words_list_file" ]]; then
    echo "$(< "$words_list_file")"
  fi
}
