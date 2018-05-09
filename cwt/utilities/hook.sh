#!/usr/bin/env bash

##
# Hooks-related utility functions.
#
# This file is sourced during core CWT bootstrap.
# @see cwt/bootstrap.sh
#
# Convention : functions names are all prefixed by "u" (for "utility").
#

##
# Triggers an "event" optionally filtered by primitives.
#
# Arguments are all optional, but this function requires at least either
# 1 action (-a) OR 1 extension (-e). See explanations below.
#
# In order to "listen" to events, some specific file(s) must use the exact path
# and name corresponding to its arguments. For a detailed list of expected
# output given various inputs :
# @see cwt/test/cwt/hook.test.sh
#
# Primitives are fundamental values dynamically generated during bootstrap :
# @see cwt/bootstrap.sh
# @see u_cwt_extend()
#
# Calling this function will source all file includes matched by subject,
# action, prefix, variant, and extension. Every extension defines a base path from
# which additional lookup paths are derived (as well as a corresponding namespace
# for glabals containing their primitives).
#
# Important notes about the 'variants' (-v) argument :
# If this function gets called without any 'variant' filter(s), it will
# automatically look for suggestions using INSTANCE_TYPE.
# Variants are combinatory. Each variant value must be an existing glabal var
# which will generate the following lookup paths given the call :
# $ hook -a 'my_action' -s 'my_subject' -v 'PROVISION_USING INSTANCE_TYPE'
# + the values PROVISION_USING='docker-compose' and INSTANCE_TYPE='dev' :
# - cwt/my_subject/my_action.hook.sh
# - cwt/my_subject/my_action.docker-compose.hook.sh
# - cwt/my_subject/my_action.dev.hook.sh
# - cwt/my_subject/my_action.docker-compose.dev.hook.sh
#
# @requires the following global variables in calling scope :
# - PROJECT_SCRIPTS
# - CWT_ACTIONS
# - CWT_SUBJECTS
# - CWT_EXTENSIONS
#
# @uses the following global variables in calling scope if they exist :
# - ${EXTENSION_NAMESPACE}_ACTIONS
# - ${EXTENSION_NAMESPACE}_SUBJECTS
#
# NB : the default separator used to concatenate parts in file names is
# the underscore '_', except for variants which use dot '.'.
# Dashes '-' are reserved for folder names and to separate "semver" suffixes.
# Semver suffixes can be used in extension folder names and variant values.
#
# Also note that each argument accepts several values by using a space to
# separate them. E.g. :
# $ hook -a 'start' -s 'stack service instance app'
#
# @examples
#
#   # 1. When providing a single action :
#   hook -a 'bootstrap'
#   # Yields the following lookup paths (ALL includes found are sourced) :
#   # (given INSTANCE_TYPE='prod')
#   # - cwt/<CWT_SUBJECTS>/bootstrap.hook.sh
#   # - cwt/<CWT_SUBJECTS>/bootstrap.prod.hook.sh
#   # - cwt/extensions/<CWT_EXTENSIONS>/<EXT_SUBJECTS>/bootstrap.hook.sh
#   # - cwt/extensions/<CWT_EXTENSIONS>/<EXT_SUBJECTS>/bootstrap.prod.hook.sh
#
#   # 2. When providing an action + a filter by subject :
#   hook -a 'init' -s 'stack'
#   # Yields the following lookup paths (ALL includes found are sourced) :
#   # (given INSTANCE_TYPE='prod')
#   # - cwt/stack/init.hook.sh
#   # - cwt/stack/init.prod.hook.sh
#   # - cwt/extensions/<CWT_EXTENSIONS>/stack/init.hook.sh
#   # - cwt/extensions/<CWT_EXTENSIONS>/stack/init.prod.hook.sh
#
#   # 3. When providing an action + a filter by 1 or several subjects + 1 or
#   #   several variants filter :
#   hook -a 'init' -s 'stack' -v 'INSTANCE_TYPE HOST_TYPE'
#   # Yields the following lookup paths (ALL includes found are sourced) :
#   # (given INSTANCE_TYPE='dev' and HOST_TYPE='local')
#   # - cwt/stack/init.hook.sh
#   # - cwt/stack/init.dev.hook.sh
#   # - cwt/stack/init.local.hook.sh
#   # - cwt/stack/init.dev.local.hook.sh
#   # - cwt/extensions/<CWT_EXTENSIONS>/stack/init.hook.sh
#   # - cwt/extensions/<CWT_EXTENSIONS>/stack/init.dev.hook.sh
#   # - cwt/extensions/<CWT_EXTENSIONS>/stack/init.local.hook.sh
#   # - cwt/extensions/<CWT_EXTENSIONS>/stack/init.dev.local.hook.sh
#
#   # 4. Extensions filter :
#   hook -e 'nodejs'
#   # Yields the following lookup paths (ALL includes found are sourced) :
#   # (given INSTANCE_TYPE='prod')
#   # - $PROJECT_SCRIPTS/extensions/nodejs/<EXT_SUBJECTS>/<SUBJECT_ACTIONS>.prod.hook.sh
#
#   # 5. Prefixes filter are exclusive by default, which means pure actions are
#   #   not included. Ex :
#   hook -a 'bootstrap' -p 'pre'
#   # Yields the following lookup paths (ALL includes found are sourced) :
#   # (given INSTANCE_TYPE='prod')
#   # - cwt/<CWT_SUBJECTS>/pre_bootstrap.hook.sh
#   # - cwt/<CWT_SUBJECTS>/pre_bootstrap.prod.hook.sh
#   # - cwt/extensions/<CWT_EXTENSIONS>/<EXT_SUBJECTS>/pre_bootstrap.hook.sh
#   # - cwt/extensions/<CWT_EXTENSIONS>/<EXT_SUBJECTS>/pre_bootstrap.prod.hook.sh
#
# We exceptionally name that function without following the usual convention.
#
hook() {
  local p_actions_filter
  local p_subjects_filter
  local p_prefixes_filter
  local p_variants_filter
  local p_extensions_filter
  local p_custom_filter
  local p_debug=0
  local p_dry_run=0

  # Parse current function arguments.
  # See https://stackoverflow.com/a/31443098
  while [ "$#" -gt 0 ]; do
    case "$1" in
      # Format : 1 dash + arg 'name' + space + value.
      -a) p_actions_filter="$2"; shift 2;;
      -s) p_subjects_filter="$2"; shift 2;;
      -p) p_prefixes_filter="$2"; shift 2;;
      -v) p_variants_filter="$2"; shift 2;;
      -e) p_extensions_filter="$2"; shift 2;;
      -c) p_custom_filter="$2"; shift 2;;
      # Flag (arg without any value).
      -d) p_debug=1; shift 1;;
      -t) p_dry_run=1; shift 1;;
      # Warn for unhandled arguments.
      -*) echo "Error in $BASH_SOURCE line $LINENO: unknown option: $1" >&2; return;;
      *) echo "Notice in $BASH_SOURCE line $LINENO: unsupported unnamed argument: $1" >&2; shift 1;;
    esac
  done

  # Enforce minimum conditions for triggering hook (see 5 in function docblock).
  if [ -z "$p_actions_filter" ] && [ -z "$p_extensions_filter" ] && [ -z "$p_variants_filter" ]; then
    echo
    echo "Error in $BASH_SOURCE line $LINENO: cannot trigger hook without either 1 action (or 1 extension + 1 variant)." >&2
    echo "-> Aborting." >&2
    echo
    return 1
  fi

  local subjects="$CWT_SUBJECTS"
  local actions="$CWT_ACTIONS"
  local extensions="$CWT_EXTENSIONS"
  local variants=""
  local prefixes=""

  local base_paths=("cwt")
  local extension
  local lowercase
  local uppercase

  # Allow using only a particular extension (see the '-p' argument).
  if [ -n "$p_extensions_filter" ]; then
    for extension in $p_extensions_filter; do
      uppercase="$extension"
      u_str_uppercase
      uppercase="${uppercase//\./_}"
      uppercase="${uppercase//-/_}"
      eval "subjects=\"\$${uppercase}_SUBJECTS\""
      eval "actions=\"\$${uppercase}_ACTIONS\""
      # Override base path for lookups.
      base_paths=("cwt/extensions/$extension")
    done

  # By default, any extension can append its own "primitives".
  # NB : this process will create duplicates e.g. when extension has identical
  # subject(s) than cwt core. They are dealt with below.
  # @see u_cwt_extend()
  elif [ -n "$extensions" ]; then
    for extension in $extensions; do
      uppercase="$extension"
      u_str_uppercase
      uppercase="${uppercase//\./_}"
      uppercase="${uppercase//-/_}"
      eval "subjects+=\" \$${uppercase}_SUBJECTS\""
      eval "actions+=\" \$${uppercase}_ACTIONS\""
      # Every extension defines an additional base path for lookups.
      base_paths+=("cwt/extensions/$extension")
    done
  fi

  # Triggering a hook requires subjects and actions.
  if [ -z "$subjects" ]; then
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO: cannot trigger hook without any subjects." >&2
    echo "-> Aborting." >&2
    echo >&2
    return 2
  fi
  if [ -z "$actions" ]; then
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO: cannot trigger hook without any actions." >&2
    echo "-> Aborting." >&2
    echo >&2
    return 3
  fi

  # Apply filters.
  local filters='subjects actions prefixes variants'
  local f
  local f_arg
  local s
  local a
  local arg_val
  local dedup
  local dedup_val
  local dedup_arr

  for f in $filters; do

    # Use the same loop to remove potential duplicate values (cf. extensions above).
    eval "dedup=\"\$$f\""
    dedup_arr=()
    for dedup_val in $dedup; do
      u_array_add_once "$dedup_val" dedup_arr
    done
    eval "$f=\"${dedup_arr[@]}\""

    eval "f_arg=\"\$p_${f}_filter\""
    if [ -z "$f_arg" ]; then
      continue
    fi

    eval "$f=''"

    case "$f" in
      subjects|prefixes|variants)
        for arg_val in $f_arg; do
          eval "$f+=\"$arg_val \""
        done
      ;;
      actions)
        for arg_val in $f_arg; do
          for s in $subjects; do
            eval "$f+=\"$s/$arg_val \""
          done
        done
      ;;
    esac
  done

  # Debug.
  # if [ $p_debug -eq 1 ]; then
  #   echo
  #   echo "debug hook call :"
  #   echo "  $(declare -p base_paths)"
  #   echo "  subjects = '$subjects'"
  #   echo "  actions = '$actions'"
  #   echo "  extensions = '$extensions'"
  #   echo "  variants = '$variants'"
  #   echo "  prefixes = '$prefixes'"
  # fi

  # Build lookup paths.
  local lookup_paths=()
  local lookup_subject

  for lookup_subject in $subjects; do
    u_hook_build_lookup_by_subject "$lookup_subject" "$p_custom_filter"
  done

  # Debug.
  if [ $p_debug -eq 1 ]; then
    u_autoload_print_lookup_paths lookup_paths "hook -a '$p_actions_filter' -s '$p_subjects_filter' -p '$p_prefixes_filter' -v '$p_variants_filter' -e '$p_extensions_filter'"
  fi

  # Source each file include (with optional override mecanism).
  # @see cwt/utilities/autoload.sh
  local inc
  for inc in "${lookup_paths[@]}"; do
    if [ -f "$inc" ]; then

      # Note : for tests, the "dry run" option prevents "override" alterations.
      # @see cwt/test/cwt/hook.test.sh
      # This is also used for operations using the same lookup mechanism. These
      # then transform the generated file paths, e.g. using string replacements.
      # @see u_stack_deps_get_lookup_paths()
      if [ $p_dry_run -eq 1 ]; then
        inc_dry_run_files_list+="$inc
"
        continue
      fi

      u_autoload_override "$inc" 'continue'
      eval "$inc_override_evaled_code"

      . "$inc"
    fi
  done
}

##
# Adds hook lookup paths by subject.
#
# Side note : we could have every subject implement every other subjects' hooks,
# if we wanted to. E.g. env/app_bootstrap.hook.sh, etc. - but #YAGNI (mentionned
# here for potential future re-evaluation).
#
# @requires the following vars in calling scope :
# - $base_paths
# - $lookup_paths
# - $filters
# - $actions
#
# @uses the following optional vars in calling scope if available :
# - $prefixes
# - $variants
# - $p_prefixes_filter
#
# @see hook()
# @see u_autoload_add_lookup_level()
#
u_hook_build_lookup_by_subject() {
  local p_subject="$1"
  local p_suffix_override="$2"

  local bp

  local a_path
  local a_parts_arr
  local a

  local x_prim
  local x_parts_arr
  local x_val
  local x_values

  local v_prim
  local v_parts_arr
  local v
  local v_values
  local v_val
  local v_flag
  local v_fallback

  # These comments illustrate possible changes for default variants (left here
  # intentionally for potential future re-evaluation).
  # local v_fallback_values='PROVISION_USING INSTANCE_TYPE HOST_TYPE'
  # local v_fallback_values='PROVISION_USING INSTANCE_TYPE'
  # local v_fallback_values='INSTANCE_TYPE HOST_TYPE'
  local v_fallback_values='INSTANCE_TYPE'

  # By default, this function will produce lookup paths using the default
  # double-extension pattern "*.hook.sh". This can be altered when using the
  # custom filter argument (-c).
  local suffix='hook.sh'
  if [[ -n "$p_suffix_override" ]]; then
    suffix="$p_suffix_override"
  fi

  for bp in "${base_paths[@]}"; do
    for a_path in $actions; do

      # Ignore actions not "belonging" to current subject.
      case "$a_path" in "$p_subject"*)

        # First, add "pure" actions suggestions - unless excluded (see prefixes).
        if [[ -z "$p_prefixes_filter" ]]; then
          lookup_paths+=("$bp/${a_path}.${suffix}")
        fi

        u_str_split1 a_parts_arr "$a_path" '/'
        a="${a_parts_arr[1]}"

        # Then add "prefixed" actions suggestions.
        for x_val in $prefixes; do
          lookup_paths+=("$bp/$p_subject/${x_val}_${a}.${suffix}")
        done

        # Finally, add the variants suggestions.
        # The "variants" primitive has overridable fallback value(s) used to
        # generate extra lookup paths by default (v_fallback_values).
        v_fallback=1

        for v_prim in $variants; do
          v_fallback=0
          eval "v_val=\"\$$v_prim\""
          if [[ "$v_values" != *"$v_val"* ]]; then
            v_values+="$v_val "
          fi
        done

        # If nothing specific was found by now, fallback to dynamic lookup
        # generation for variants.
        if [[ $v_fallback -eq 1 ]]; then
          for v in $v_fallback_values; do
            eval "v_val=\"\$$v\""
            if [[ "$v_values" != *"$v_val"* ]]; then
              v_values+="$v_val "
            fi
          done
        fi

        # Now that we fetched variants actual values, add them as as suggestions
        # unless excluded (see prefixes). These are combinatory, e.g. :
        # - init.dev.local.hook.sh
        # - bootstrap.docker-compose.dev.hook.sh
        # - bootstrap.docker-compose.prod.remote.hook.sh
        u_str_subsequences "$v_values" '.'
        if [[ -z "$p_prefixes_filter" ]]; then
          for v_val in $str_subsequences; do
            u_autoload_add_lookup_level "$bp/$p_subject/${a}." "$suffix" "$v_val" lookup_paths
          done
        fi

        # Implement prefix + variant lookup paths, e.g. :
        # pre_bootstrap.docker-compose.hook.sh
        for x_val in $prefixes; do
          for v_val in $str_subsequences; do
            u_autoload_add_lookup_level "$bp/$p_subject/${x_val}_${a}." "$suffix" "$v_val" lookup_paths
          done
        done
      esac
    done
  done
}
