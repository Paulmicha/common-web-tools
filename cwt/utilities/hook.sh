#!/usr/bin/env bash

##
# Hooks-related utility functions.
#
# This file is dynamically loaded.
# @see cwt/bootstrap.sh
#
# Convention : functions names are all prefixed by "u" (for "utility").
#

##
# Triggers an "event" optionally filtered by primitives.
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
# If this function gets called without any 'variant' filter(s), it will
# automatically look for suggestions using the following fallback values :
# - PROVISION_USING
# - INSTANCE_TYPE
#
# Variants are combinatory. Each variant value must be an existing glabal var
# which will generate the following lookup paths given the call :
# $ hook -a 'my_action' -s 'my_subject' -v 'PROVISION_USING INSTANCE_TYPE'
# + the values PROVISION_USING='docker-compose-2.3' and INSTANCE_TYPE='dev' :
# - cwt/my_subject/my_action.hook.sh
# - cwt/my_subject/my_action.docker-compose.hook.sh
# - cwt/my_subject/my_action.docker-compose-2.3.hook.sh
# - cwt/my_subject/my_action.dev.hook.sh
# - cwt/my_subject/my_action.docker-compose.dev.hook.sh
# - cwt/my_subject/my_action.docker-compose-2.3.dev.hook.sh
#
# @requires the following global variables in calling scope :
# - CWT_CUSTOM_DIR
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
#   # - cwt/<CWT_SUBJECTS>/bootstrap.hook.sh
#   # - cwt/<CWT_SUBJECTS>/bootstrap<.VARIANTS+semver>.hook.sh
#   # - $CWT_CUSTOM_DIR/<CWT_EXTENSIONS+semver>/<EXT_SUBJECTS>/bootstrap.hook.sh
#   # - $CWT_CUSTOM_DIR/<CWT_EXTENSIONS+semver>/<EXT_SUBJECTS>/bootstrap<.VARIANTS+semver>.hook.sh
#
#   # 2. When providing an action + a filter by subject :
#   hook -a 'init' -s 'stack'
#   # Yields the following lookup paths (ALL includes found are sourced) :
#   # - cwt/stack/init.hook.sh
#   # - cwt/stack/init<.VARIANTS+semver>.hook.sh
#   # - $CWT_CUSTOM_DIR/<CWT_EXTENSIONS+semver>/stack/init.hook.sh
#   # - $CWT_CUSTOM_DIR/<CWT_EXTENSIONS+semver>/stack/init<.VARIANTS+semver>.hook.sh
#
#   # 3. When providing an action + a filter by 1 or several subjects + 1 or
#   #   several variants filter :
#   hook -a 'init' -s 'stack' -v 'HOST_TYPE'
#   # Yields the following lookup paths (ALL includes found are sourced) :
#   # See 3. but only with provided variants.
#
#   # 4. Arguments order may be swapped, but it requires at least either :
#   #   - 1 action
#   #   - 1 extension + 1 variant
#   hook -e 'nodejs' -v 'INSTANCE_TYPE'
#   # Yields the following lookup paths (ALL includes found are sourced) :
#   # - $CWT_CUSTOM_DIR/extensions/nodejs<+semver>/<EXT_SUBJECTS>/<SUBJECT_ACTIONS><.INSTANCE_TYPE>.hook.sh
#
#   # 5. Prefixes filter :
#   hook -a 'bootstrap' -p 'pre'
#   # Yields the following lookup paths (ALL includes found are sourced) :
#   # See 1. but only with provided prefixes.
#
# We exceptionally name that function without following the usual convention.
#
hook() {
  local p_actions_filter
  local p_subjects_filter
  local p_prefixes_filter
  local p_variants_filter
  local p_extensions_filter
  local p_debug
  local p_dry_run

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
      # Flag (arg without any value).
      -d) p_debug=1; shift 1;;
      -t) p_dry_run=1; shift 1;;
      # Warn for unhandled arguments.
      -*) echo "Error in $BASH_SOURCE line $LINENO: unknown option: $1" >&2; return;;
      *) echo "Notice in $BASH_SOURCE line $LINENO: unsupported unnamed argument: $1" >&2; shift 1;;
    esac
  done

  # Enforce minimum conditions for triggering hook (see 5 in function docblock).
  if [[ -z "$p_actions_filter" ]] && [[ -z "$p_extensions_filter" ]] && [[ -z "$p_variants_filter" ]]; then
    echo
    echo "Error in $BASH_SOURCE line $LINENO: cannot trigger hook without either 1 action filter (or 1 extension + 1 variant)." >&2
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
  local extensions_dir="$CWT_CUSTOM_DIR/extensions"
  local extension
  local lowercase
  local uppercase

  # Allow using only a particular extension (see the '-p' argument).
  if [[ -n "$p_extension_filter" ]]; then
    for extension in $p_extension_filter; do
      uppercase="$extension"
      u_str_uppercase
      uppercase="${uppercase//\./_}"
      uppercase="${uppercase//-/_}"
      eval "subjects=\"\$${uppercase}_SUBJECTS\""
      eval "actions=\"\$${uppercase}_ACTIONS\""
      # Override base path for lookups.
      base_paths=("$extensions_dir/$extension")
    done

  # By default, any extension can append its own "primitives".
  # NB : this process will create duplicates e.g. when extension has identical
  # subject(s) than cwt core. They are dealt with below.
  # @see u_cwt_extend()
  elif [[ -n "$extensions" ]]; then
    for extension in $extensions; do
      uppercase="$extension"
      u_str_uppercase
      uppercase="${uppercase//\./_}"
      uppercase="${uppercase//-/_}"
      eval "subjects+=\" \$${uppercase}_SUBJECTS\""
      eval "actions+=\" \$${uppercase}_ACTIONS\""
      # Every extension defines an additional base path for lookups.
      base_paths+=("$extensions_dir/$extension")
    done
  fi

  # Triggering a hook requires subjects and actions.
  if [[ -z "$subjects" ]]; then
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO: cannot trigger hook without any subjects." >&2
    echo "-> Aborting." >&2
    echo >&2
    return 2
  fi
  if [[ -z "$actions" ]]; then
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
    if [[ -z "$f_arg" ]]; then
      continue
    fi

    eval "$f=''"

    case "$f" in
      subjects)
        for arg_val in $f_arg; do
          eval "$f+=\" $f_arg \""
        done
      ;;
      actions)
        for arg_val in $f_arg; do
          for s in $subjects; do
            eval "$f+=\" $s/$f_arg \""
          done
        done
      ;;
      prefixes|variants)
        for arg_val in $f_arg; do
          for s in $subjects; do
            for a in $actions; do
              eval "$f+=\" $s/$a/$f_arg \""
            done
          done
        done
      ;;
    esac
  done

  # Build lookup paths.
  local lookup_paths=()
  local lookup_subject

  for lookup_subject in $subjects; do
    u_hook_build_lookup_by_subject "$lookup_subject"
  done

  # Debug.
  if [[ $p_debug == 1 ]]; then
    u_autoload_print_lookup_paths lookup_paths "hook -a '$p_actions_filter' -s '$p_subjects_filter' -x '$p_prefixes_filter' -v '$p_variants_filter' -p '$p_extensions_filter'"
  fi

  # Source each file include (with optional override mecanism).
  # @see cwt/utilities/autoload.sh
  local inc
  for inc in "${lookup_paths[@]}"; do
    if [[ -f "$inc" ]]; then

      # Note : for tests, the "dry run" option prevents "override" alterations.
      # @see cwt/test/cwt/hook.test.sh
      if [[ $p_dry_run == 1 ]]; then
        inc_dry_run_files_list+="$inc "
        continue
      fi

      u_autoload_override "$inc" 'continue'
      eval "$inc_override_evaled_code"

      . "$inc"
    fi
  done
}

##
# Adds lookup paths by subject.
#
# EVOL we *could* have every subject implement every other subjects' hooks,
# if we wanted to. E.g. env/app_bootstrap.hook.sh, etc.
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
#
# @see hook()
#
u_hook_build_lookup_by_subject() {
  local p_subject="$1"

  local bp

  local a_path
  local a_parts_arr
  local a

  local x_prim
  local x_parts_arr
  local x
  local x_values

  local v_prim
  local v_parts_arr
  local v
  local v_values
  local v_val
  local v_flag
  local v_fallback
  # local v_fallback_values='PROVISION_USING INSTANCE_TYPE HOST_TYPE'
  # local v_fallback_values='PROVISION_USING INSTANCE_TYPE'
  # local v_fallback_values='INSTANCE_TYPE HOST_TYPE'
  local v_fallback_values='INSTANCE_TYPE'

  for bp in "${base_paths[@]}"; do
    for a_path in $actions; do

      # Ignore actions not "belonging" to current subject.
      case "$a_path" in "$p_subject"*)
        lookup_paths+=("$bp/${a_path}.hook.sh")

        u_str_split1 a_parts_arr "$a_path" '/'
        a="${a_parts_arr[1]}"

        # "prefixes" and "variants" primitives are special : unless nothing
        # explicitly alters them (see dotfiles by subject + by action in
        # cwt/utilities/cwt.sh), hardcoded fallback values are used to generate
        # new lookup paths automatically.
        # NB : we rely on the invariability of the "positions" of primitives'
        # values - e.g. subjects MUST always be 1st, actions MUST always be
        # 2nd, and prefixes + variants MUST always come last.
        # @see u_cwt_extend()
        v_fallback=1

        for x_prim in $prefixes; do
          case "$x_prim" in "$bp/$a_path"*)
            u_str_split1 x_parts_arr "$x_prim" '/'
            x="${x_parts_arr[2]}"
            lookup_paths+=("$bp/$p_subject/${x}_${a}.hook.sh")
            x_values+="$x "
          esac
        done

        for v_prim in $variants; do
          case "$v_prim" in "$bp/$a_path"*)
            v_fallback=0
            u_str_split1 v_parts_arr "$v_prim" '/'
            v="${v_parts_arr[2]}"
            eval "v_val=\"\$$v_prim\""
            # u_autoload_add_lookup_level "$bp/$p_subject/" "${a}.hook.sh" "$v_val" lookup_paths '' '/'
            u_autoload_add_lookup_level "$bp/$p_subject/${a}." "hook.sh" "$v_val" lookup_paths
            v_values+="$v_val "
          esac
        done

        # If nothing specific was found by now, fallback to dynamic lookup
        # generation for variants.
        # specify if it's justified to look for certain variants or prefixes by
        # using corresponding arguments in hook().
        if [[ $v_fallback -eq 1 ]]; then
          for v in $v_fallback_values; do
            eval "v_val=\"\$$v\""
            # u_autoload_add_lookup_level "$bp/$p_subject/" "${a}.hook.sh" "$v_val" lookup_paths '' '/'
            u_autoload_add_lookup_level "$bp/$p_subject/${a}." "hook.sh" "$v_val" lookup_paths
            v_values+="$v_val "
          done
        fi

        # Implement combinatory variant lookup paths, e.g. :
        # bootstrap.docker-compose.dev.hook.sh
        local combi_v_val
        for v_val in $v_values; do
          for combi_v_val in $v_values; do
            if [[ "$combi_v_val" != "$v_val" ]]; then
              u_autoload_add_lookup_level "$bp/$p_subject/${a}.${v_val}." "hook.sh" "$combi_v_val" lookup_paths
            fi
          done
        done

        # Implement prefix + variant lookup paths, e.g. :
        # pre_bootstrap.docker-compose.hook.sh
        for x in $x_values; do
          for v_val in $v_values; do
            u_autoload_add_lookup_level "$bp/$p_subject/${x}_${a}." "hook.sh" "$v_val" lookup_paths

            # Implement combinatory variant lookup paths by prefix, e.g. :
            # pre_bootstrap.docker-compose.dev.hook.sh
            # TODO make opt-in or remove ? #YAGNI
            for combi_v_val in $v_values; do
              if [[ "$combi_v_val" != "$v_val" ]]; then
                u_autoload_add_lookup_level "$bp/$p_subject/${a}.${v_val}." "hook.sh" "$combi_v_val" lookup_paths
              fi
            done
          done
        done
      esac
    done
  done
}
