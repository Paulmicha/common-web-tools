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
# Triggers an "event" optionally filtered by "primitives".
#
# Primitives are fundamental values dynamically generated during bootstrap :
# @see cwt/bootstrap.sh
# @see u_cwt_extend()
#
# Calling this function will source all file includes matched by subject,
# action, prefix, variant, and preset. Every preset defines a base path from
# which additional lookup paths are derived.
# Also attempts to call functions matching the corresponding lookup patterns.
#
# @requires the following global variables in calling scope :
# - NAMESPACE
# - CWT_CUSTOM_DIR
# - CWT_ACTIONS or ${NAMESPACE}_ACTIONS
# - CWT_SUBJECTS or ${NAMESPACE}_SUBJECTS
# - CWT_PREFIXES or ${NAMESPACE}_PREFIXES
# - CWT_VARIANTS or ${NAMESPACE}_VARIANTS
# - CWT_PRESETS or ${NAMESPACE}_PRESETS
#
# NB : the default separator used to concatenate lookup parts in file names is
# the underscore '_'.
# Dashes '-' are reserved for folder names and to separate "semver" suffixes.
#
# @examples
#
#   # 1. When providing a single action :
#   hook -a 'bootstrap'
#   # Yields the following lookup paths (ALL includes found are sourced) :
#   # - cwt/<CWT_SUBJECTS>/bootstrap.hook.sh
#   # - cwt/<CWT_SUBJECTS>/<CWT_PREFIXES+sep>bootstrap.hook.sh
#   # - cwt/<CWT_SUBJECTS>/bootstrap<sep+CWT_VARIANTS>.hook.sh
#   # - cwt/<CWT_SUBJECTS>/<CWT_PREFIXES+sep>bootstrap<sep+CWT_VARIANTS>.hook.sh
#   # - $CWT_CUSTOM_DIR/<CWT_PRESETS+semver>/<CWT_SUBJECTS>/bootstrap.hook.sh
#   # - $CWT_CUSTOM_DIR/<CWT_PRESETS+semver>/<CWT_SUBJECTS>/<CWT_PREFIXES+sep>bootstrap.hook.sh
#   # - $CWT_CUSTOM_DIR/<CWT_PRESETS+semver>/<CWT_SUBJECTS>/bootstrap<sep+CWT_VARIANTS>.hook.sh
#   # - $CWT_CUSTOM_DIR/<CWT_PRESETS+semver>/<CWT_SUBJECTS>/<CWT_PREFIXES+sep>bootstrap<sep+CWT_VARIANTS>.hook.sh
#
#   # 2. When providing an action + a filter by subject :
#   hook -a 'init' -s 'stack'
#   # Yields the following lookup paths (ALL includes found are sourced) :
#   # - cwt/stack/init.hook.sh
#   # - cwt/stack/<CWT_PREFIXES+sep>init.hook.sh
#   # - cwt/stack/init<sep+CWT_VARIANTS>.hook.sh
#   # - $CWT_CUSTOM_DIR/<CWT_PRESETS+semver>/stack/init.hook.sh
#   # - $CWT_CUSTOM_DIR/<CWT_PRESETS+semver>/stack/<CWT_PREFIXES+sep>init.hook.sh
#   # - $CWT_CUSTOM_DIR/<CWT_PRESETS+semver>/stack/init<sep+CWT_VARIANTS>.hook.sh
#   # - $CWT_CUSTOM_DIR/<CWT_PRESETS+semver>/stack/<CWT_PREFIXES+sep>init<sep+CWT_VARIANTS>.hook.sh
#
#   # 3. When providing an action + a filter by several subjects :
#   hook -a 'apply_ownership_and_perms' -s 'stack app'
#   # Yields the following lookup paths (ALL includes found are sourced) :
#   # See 2. for each subject.
#
#   # 4. When providing an action + a filter by 1 or several subjects + 1 or
#   #   several variants filter :
#   hook -a 'provision' -s 'stack' -v 'PROVISION_USING HOST_TYPE'
#   # Yields the following lookup paths (ALL includes found are sourced) :
#   # See 3. but only with provided variants.
#
#   # 5. Arguments order may be swapped, but it requires at least either :
#   #   - 1 action
#   #   - 1 preset + 1 variant
#   hook -p 'nodejs' -v 'INSTANCE_TYPE'
#   # Yields the following lookup paths (ALL includes found are sourced) :
#   # - $CWT_CUSTOM_DIR/nodejs<+semver>/<CWT_SUBJECTS>/<CWT_PREFIXES+sep><CWT_ACTIONS+sep>init<sep+CWT_VARIANTS>.hook.sh
#
#   # 6. Prefixes filter :
#   hook -a 'bootstrap' -x 'pre'
#   # Yields the following lookup paths (ALL includes found are sourced) :
#   # See 1. but only with provided prefixes.
#
#   # 7. TODO evaluate removal of NAMESPACE filter.
#
# We exceptionally name that function without following the usual convention.
#
hook() {
  local p_actions_filter
  local p_subjects_filter
  local p_prefixes_filter
  local p_variants_filter
  local p_presets_filter
  # local p_namespace_filter # [wip] evaluate merging namespace and preset for current purpose.
  local p_debug

  # Parse current function arguments.
  # See https://stackoverflow.com/a/31443098
  while [ "$#" -gt 0 ]; do
    case "$1" in
      # Format : 1 dash + arg 'name' + space + value.
      -a) p_actions_filter="$2"; shift 2;;
      -s) p_subjects_filter="$2"; shift 2;;
      -x) p_prefixes_filter="$2"; shift 2;;
      -v) p_variants_filter="$2"; shift 2;;
      -p) p_presets_filter="$2"; shift 2;;
      # -n) p_namespace_filter="$2"; shift 2;; # [wip] evaluate merging namespace and preset for current purpose.
      # Flag (arg without any value).
      -d) p_debug=1; shift 1;;
      # Warn for unhandled arguments.
      -*) echo "Error in $BASH_SOURCE line $LINENO: unknown option: $1" >&2; return;;
      *) echo "Notice in $BASH_SOURCE line $LINENO: unsupported unnamed argument: $1" >&2; shift 1;;
    esac
  done

  # Enforce minimum conditions for triggering hook (see 5 in function docblock).
  if [[ (-z "$p_actions_filter") && (-z "$p_presets_filter") && (-z "$p_variants_filter") ]]; then
    echo
    echo "Error in $BASH_SOURCE line $LINENO: cannot trigger hook without either 1 action filter (or 1 preset + 1 variant)." >&2
    echo "-> Aborting."
    echo
    return 1
  fi

  local subjects="$CWT_SUBJECTS"
  local actions="$CWT_ACTIONS"
  local variants="$CWT_VARIANTS"
  local presets="$CWT_PRESETS"
  local prefixes="$CWT_PREFIXES"

  local base_paths=("cwt")
  local presets_dir="$CWT_CUSTOM_DIR"
  local preset
  local lowercase
  local uppercase

  # Allow using only a particular preset (see the '-p' argument).
  if [[ -n "$p_preset_filter" ]]; then
    for preset in $p_preset_filter; do
      uppercase="$preset"
      u_str_uppercase
      eval "subjects=\"\$${uppercase}_SUBJECTS\""
      eval "actions=\"\$${uppercase}_ACTIONS\""
      eval "variants=\"\$${uppercase}_VARIANTS\""
      eval "presets=\"\$${uppercase}_PRESETS\"" # TODO evaluate removing "presets of presets".
      eval "prefixes=\"\$${uppercase}_PREFIXES\""
      # Override base path for lookups.
      base_paths=("$presets_dir/$preset")
    done

  # By default, any preset can append its own "primitives".
  # @see u_cwt_extend()
  elif [[ -n "$presets" ]]; then
    for preset in $presets; do
      uppercase="$preset"
      u_str_uppercase
      eval "subjects+=\" \$${uppercase}_SUBJECTS\""
      eval "actions+=\" \$${uppercase}_ACTIONS\""
      eval "variants+=\" \$${uppercase}_VARIANTS\""
      eval "presets+=\" \$${uppercase}_PRESETS\"" # TODO evaluate removing "presets of presets".
      eval "prefixes+=\" \$${uppercase}_PREFIXES\""
      # Every preset defines an additional base path for lookups.
      base_paths+=("$presets_dir/$preset")
    done
  fi

  # Triggering a hook requires subjects and actions.
  if [[ -z "$subjects" ]]; then
    echo
    echo "Error in $BASH_SOURCE line $LINENO: cannot trigger hook without any subjects." >&2
    echo "-> Aborting."
    echo
    return 2
  fi
  if [[ -z "$actions" ]]; then
    echo
    echo "Error in $BASH_SOURCE line $LINENO: cannot trigger hook without any actions." >&2
    echo "-> Aborting."
    echo
    return 3
  fi

  # Apply filters.
  local filters='subjects actions prefixes variants' # TODO check order impact.
  local f
  local f_arg
  local s
  local a
  local arg_val

  for f in $filters; do

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
  local bp
  local lookup_subject
  local lookup_preset

  for lookup_subject in $subjects; do
    u_hook_build_lookup_by_subject "$lookup_subject"
  done

  if [[ -n "$presets" ]]; then
    for lookup_preset in $presets; do
      u_hook_build_lookup_by_preset "$p"
    done
  fi

  # Debug.
  if [[ $p_debug == 1 ]]; then
    u_autoload_print_lookup_paths lookup_paths "hook -a '$p_actions_filter' -s '$p_subjects_filter' -x '$p_prefixes_filter' -v '$p_variants_filter' -p '$p_presets_filter'"
  fi

  # Source each file include (with optional override mecanism).
  # @see cwt/utilities/autoload.sh
  local inc
  for inc in "${lookup_paths[@]}"; do
    if [[ -f "$inc" ]]; then
      eval $(u_autoload_override "$inc" 'continue')
      . "$inc"
    fi
    # TODO build matching function names to call ?
  done
}

##
# TODO [wip] Adds lookup paths by subject.
#
# TODO we *could* have every subject implement every other subjects' hooks,
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
  local x_fallback
  local x_fallback_values='pre post'

  local v_prim
  local v_parts_arr
  local v
  local v_values
  local v_val
  local v_flag
  local v_fallback
  local v_fallback_values='PROVISION_USING INSTANCE_TYPE'

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
        # TODO see if we can process dotfiles only once here (all at once).
        x_fallback=1
        v_fallback=1

        for x_prim in $prefixes; do
          case "$x_prim" in "$a_path"*)
            x_fallback=0
            u_str_split1 x_parts_arr "$x_prim" '/'
            x="${x_parts_arr[2]}"
            lookup_paths+=("$bp/$p_subject/${x}_${a}.hook.sh")
            x_values+="$x "
          esac
        done

        for v_prim in $variants; do
          case "$v_prim" in "$a_path"*)
            v_fallback=0
            u_str_split1 v_parts_arr "$v_prim" '/'
            v="${v_parts_arr[2]}"
            eval "v_val=\"\$$v_prim\""
            u_autoload_add_lookup_level "$bp/$p_subject/" "${a}.hook.sh" "$v_val" lookup_paths '' '/'
            u_autoload_add_lookup_level "$bp/$p_subject/${a}." "hook.sh" "$v_val" lookup_paths
            v_values+="$v_val "
          esac
        done

        # If nothing specific was found by now, fallback to dynamic lookup
        # generation for prefixes and variants.
        if [[ $x_fallback == 1 ]]; then
          for x in $x_fallback_values; do
            lookup_paths+=("$bp/$p_subject/${x}_${a}.hook.sh")
            x_values+="$x "
          done
        fi
        if [[ $v_fallback == 1 ]]; then
          for v in $v_fallback_values; do
            eval "v_val=\"\$$v\""
            u_autoload_add_lookup_level "$bp/$p_subject/" "${a}.hook.sh" "$v_val" lookup_paths '' '/'
            u_autoload_add_lookup_level "$bp/$p_subject/${a}." "hook.sh" "$v_val" lookup_paths
            v_values+="$v_val "
          done
        fi

        # Implement prefix + variant lookup paths.
        # e.g. pre_bootstrap.docker-compose.hook.sh
        for x in $x_values; do
          for v_val in $v_values; do
            u_autoload_add_lookup_level "$p/" "${x}_${a}.hook.sh" "$v_val" lookup_paths '' '/'
            u_autoload_add_lookup_level "$p/${x}_${a}." "hook.sh" "$v_val" lookup_paths
          done
        done
      esac
    done
  done
}

##
# TODO [wip] Adds lookup paths by preset.
#
# @requires the following vars in calling scope :
# - $lookup_paths
# - $filters
# - $actions
# - $subjects
#
# @uses the following optional vars in calling scope if available :
# - $prefixes
# - $variants
#
# @see hook()
#
u_hook_build_lookup_by_preset() {
  local p_path="$1"

  echo "  u_hook_build_lookup_by_preset $@"

  # lookup_paths+=("$p_path/${p_subject}/${p_event}.hook.sh")
  # u_autoload_add_lookup_level "$p_path/${p_subject}/" "${p_event}.hook.sh" "$PROVISION_USING" lookup_paths '' '/'

  # lookup_paths+=("$p_path/${p_subject}_${p_event}.hook.sh")
  # u_autoload_add_lookup_level "$p_path/${p_subject}_${p_event}." "hook.sh" "$PROVISION_USING" lookup_paths
}


##
# Sources scripts for specific app.
#
# @requires the following global in calling scope :
# - $PROJECT_STACK
# - $PROVISION_USING
#
# @param 1 String : prefix for hook files lookups.
# @param 2 String : suffix for hook files lookups.
# @param 3 [optional] String : additional variant for hook files lookups.
# @param 4 [optional] String : additional "base" lookups.
#
# @example
#   PROJECT_STACK='drupal-8.4--p-contenta-1,redis,solr'
#   PROVISION_USING='docker-compose'
#
#   u_hook_app 'apply' 'ownership_and_perms'
#
#   # Yields the following lookup paths :
#     cwt/app/drupal/apply/ownership_and_perms.hook.sh
#     cwt/app/drupal/apply/docker-compose/ownership_and_perms.hook.sh
#     cwt/app/drupal/apply_ownership_and_perms.hook.sh
#     cwt/app/drupal/apply_ownership_and_perms.docker-compose.hook.sh
#     cwt/app/drupal/8/apply/ownership_and_perms.hook.sh
#     cwt/app/drupal/8/apply/docker-compose/ownership_and_perms.hook.sh
#     cwt/app/drupal/8/apply_ownership_and_perms.hook.sh
#     cwt/app/drupal/8/apply_ownership_and_perms.docker-compose.hook.sh
#     cwt/app/drupal/8/4/apply/ownership_and_perms.hook.sh
#     cwt/app/drupal/8/4/apply/docker-compose/ownership_and_perms.hook.sh
#     cwt/app/drupal/8/4/apply_ownership_and_perms.hook.sh
#     cwt/app/drupal/8/4/apply_ownership_and_perms.docker-compose.hook.sh
#     cwt/app/drupal/presets/contenta/apply/ownership_and_perms.hook.sh
#     cwt/app/drupal/presets/contenta/apply/docker-compose/ownership_and_perms.hook.sh
#     cwt/app/drupal/presets/contenta/apply_ownership_and_perms.hook.sh
#     cwt/app/drupal/presets/contenta/apply_ownership_and_perms.docker-compose.hook.sh
#     cwt/app/drupal/presets/contenta/1/apply/ownership_and_perms.hook.sh
#     cwt/app/drupal/presets/contenta/1/apply/docker-compose/ownership_and_perms.hook.sh
#     cwt/app/drupal/presets/contenta/1/apply_ownership_and_perms.hook.sh
#     cwt/app/drupal/presets/contenta/1/apply_ownership_and_perms.docker-compose.hook.sh
#     cwt/app/drupal/8/presets/contenta/apply/ownership_and_perms.hook.sh
#     cwt/app/drupal/8/presets/contenta/apply/docker-compose/ownership_and_perms.hook.sh
#     cwt/app/drupal/8/presets/contenta/apply_ownership_and_perms.hook.sh
#     cwt/app/drupal/8/presets/contenta/apply_ownership_and_perms.docker-compose.hook.sh
#     cwt/app/drupal/8/presets/contenta/1/apply/ownership_and_perms.hook.sh
#     cwt/app/drupal/8/presets/contenta/1/apply/docker-compose/ownership_and_perms.hook.sh
#     cwt/app/drupal/8/presets/contenta/1/apply_ownership_and_perms.hook.sh
#     cwt/app/drupal/8/presets/contenta/1/apply_ownership_and_perms.docker-compose.hook.sh
#     cwt/app/drupal/8/4/presets/contenta/apply/ownership_and_perms.hook.sh
#     cwt/app/drupal/8/4/presets/contenta/apply/docker-compose/ownership_and_perms.hook.sh
#     cwt/app/drupal/8/4/presets/contenta/apply_ownership_and_perms.hook.sh
#     cwt/app/drupal/8/4/presets/contenta/apply_ownership_and_perms.docker-compose.hook.sh
#     cwt/app/drupal/8/4/presets/contenta/1/apply/ownership_and_perms.hook.sh
#     cwt/app/drupal/8/4/presets/contenta/1/apply/docker-compose/ownership_and_perms.hook.sh
#     cwt/app/drupal/8/4/presets/contenta/1/apply_ownership_and_perms.hook.sh
#     cwt/app/drupal/8/4/presets/contenta/1/apply_ownership_and_perms.docker-compose.hook.sh
#     cwt/custom/presets/contenta/apply/ownership_and_perms.hook.sh
#     cwt/custom/presets/contenta/apply/docker-compose/ownership_and_perms.hook.sh
#     cwt/custom/presets/contenta/apply_ownership_and_perms.hook.sh
#     cwt/custom/presets/contenta/apply_ownership_and_perms.docker-compose.hook.sh
#     cwt/custom/presets/contenta/1/apply/ownership_and_perms.hook.sh
#     cwt/custom/presets/contenta/1/apply/docker-compose/ownership_and_perms.hook.sh
#     cwt/custom/presets/contenta/1/apply_ownership_and_perms.hook.sh
#     cwt/custom/presets/contenta/1/apply_ownership_and_perms.docker-compose.hook.sh
#
u_hook_app() {
  if [[ -z "$APP" ]]; then
    u_stack_get_specs "$PROJECT_STACK"
  fi

  local lookup_subjects="app app/$APP $CWT_CUSTOM_DIR"
  if [[ -n "$4" ]]; then
    lookup_subjects+=" $4"
  fi

  # Also match app version specific scripts.
  if [[ -n "$APP_VERSION" ]]; then
    local app_v=''
    local app_version_arr=()
    local app_path="app/$APP"
    u_str_split1 app_version_arr "$APP_VERSION" '.'

    for app_v in "${app_version_arr[@]}"; do
      app_path+="/$app_v"
      lookup_subjects+=" $app_path"
    done
  fi

  u_hook "$1" "$2" "$3" "$lookup_subjects"
}

##
# Sources scripts matching specific path & filename by subject + event (phase).
#
# @requires the following global in calling scope :
# - $PROJECT_STACK
# - $PROVISION_USING
#
# @param 1 String : the "subject" (app, env, git, provision, remote, stack).
# @param 2 String : the event name.
# @param 3 [optional] String : the event "phase".
# @param 4 [optional] String : subjects lookup (base paths).
#
# @example 1 : event only
#
#   PROJECT_STACK='drupal-8.4--p-contenta-1,redis,solr'
#   PROVISION_USING='docker-compose'
#   u_hook 'stack' 'setup'
#
#   # Yields the following lookup paths :
#     cwt/app/stack/setup.hook.sh
#     cwt/app/stack/docker-compose/setup.hook.sh
#     cwt/app/stack_setup.hook.sh
#     cwt/app/stack_setup.docker-compose.hook.sh
#     cwt/env/stack/setup.hook.sh
#     cwt/env/stack/docker-compose/setup.hook.sh
#     cwt/env/stack_setup.hook.sh
#     cwt/env/stack_setup.docker-compose.hook.sh
#     cwt/git/stack/setup.hook.sh
#     cwt/git/stack/docker-compose/setup.hook.sh
#     cwt/git/stack_setup.hook.sh
#     cwt/git/stack_setup.docker-compose.hook.sh
#     cwt/provision/stack/setup.hook.sh
#     cwt/provision/stack/docker-compose/setup.hook.sh
#     cwt/provision/stack_setup.hook.sh
#     cwt/provision/stack_setup.docker-compose.hook.sh
#     cwt/remote/stack/setup.hook.sh
#     cwt/remote/stack/docker-compose/setup.hook.sh
#     cwt/remote/stack_setup.hook.sh
#     cwt/remote/stack_setup.docker-compose.hook.sh
#     cwt/stack/docker-compose/setup.hook.sh
#     cwt/stack/docker-compose.setup.hook.sh
#     cwt/app/presets/contenta/stack/setup.hook.sh
#     cwt/app/presets/contenta/stack/docker-compose/setup.hook.sh
#     cwt/app/presets/contenta/stack_setup.hook.sh
#     cwt/app/presets/contenta/stack_setup.docker-compose.hook.sh
#     cwt/app/presets/contenta/1/stack/setup.hook.sh
#     cwt/app/presets/contenta/1/stack/docker-compose/setup.hook.sh
#     cwt/app/presets/contenta/1/stack_setup.hook.sh
#     cwt/app/presets/contenta/1/stack_setup.docker-compose.hook.sh
#     cwt/env/presets/contenta/stack/setup.hook.sh
#     cwt/env/presets/contenta/stack/docker-compose/setup.hook.sh
#     cwt/env/presets/contenta/stack_setup.hook.sh
#     cwt/env/presets/contenta/stack_setup.docker-compose.hook.sh
#     cwt/env/presets/contenta/1/stack/setup.hook.sh
#     cwt/env/presets/contenta/1/stack/docker-compose/setup.hook.sh
#     cwt/env/presets/contenta/1/stack_setup.hook.sh
#     cwt/env/presets/contenta/1/stack_setup.docker-compose.hook.sh
#     cwt/git/presets/contenta/stack/setup.hook.sh
#     cwt/git/presets/contenta/stack/docker-compose/setup.hook.sh
#     cwt/git/presets/contenta/stack_setup.hook.sh
#     cwt/git/presets/contenta/stack_setup.docker-compose.hook.sh
#     cwt/git/presets/contenta/1/stack/setup.hook.sh
#     cwt/git/presets/contenta/1/stack/docker-compose/setup.hook.sh
#     cwt/git/presets/contenta/1/stack_setup.hook.sh
#     cwt/git/presets/contenta/1/stack_setup.docker-compose.hook.sh
#     cwt/provision/presets/contenta/stack/setup.hook.sh
#     cwt/provision/presets/contenta/stack/docker-compose/setup.hook.sh
#     cwt/provision/presets/contenta/stack_setup.hook.sh
#     cwt/provision/presets/contenta/stack_setup.docker-compose.hook.sh
#     cwt/provision/presets/contenta/1/stack/setup.hook.sh
#     cwt/provision/presets/contenta/1/stack/docker-compose/setup.hook.sh
#     cwt/provision/presets/contenta/1/stack_setup.hook.sh
#     cwt/provision/presets/contenta/1/stack_setup.docker-compose.hook.sh
#     cwt/remote/presets/contenta/stack/setup.hook.sh
#     cwt/remote/presets/contenta/stack/docker-compose/setup.hook.sh
#     cwt/remote/presets/contenta/stack_setup.hook.sh
#     cwt/remote/presets/contenta/stack_setup.docker-compose.hook.sh
#     cwt/remote/presets/contenta/1/stack/setup.hook.sh
#     cwt/remote/presets/contenta/1/stack/docker-compose/setup.hook.sh
#     cwt/remote/presets/contenta/1/stack_setup.hook.sh
#     cwt/remote/presets/contenta/1/stack_setup.docker-compose.hook.sh
#     cwt/stack/presets/contenta/stack/setup.hook.sh
#     cwt/stack/presets/contenta/stack/docker-compose/setup.hook.sh
#     cwt/stack/presets/contenta/stack_setup.hook.sh
#     cwt/stack/presets/contenta/stack_setup.docker-compose.hook.sh
#     cwt/stack/presets/contenta/1/stack/setup.hook.sh
#     cwt/stack/presets/contenta/1/stack/docker-compose/setup.hook.sh
#     cwt/stack/presets/contenta/1/stack_setup.hook.sh
#     cwt/stack/presets/contenta/1/stack_setup.docker-compose.hook.sh
#     cwt/custom/presets/contenta/stack/setup.hook.sh
#     cwt/custom/presets/contenta/stack/docker-compose/setup.hook.sh
#     cwt/custom/presets/contenta/stack_setup.hook.sh
#     cwt/custom/presets/contenta/stack_setup.docker-compose.hook.sh
#     cwt/custom/presets/contenta/1/stack/setup.hook.sh
#     cwt/custom/presets/contenta/1/stack/docker-compose/setup.hook.sh
#     cwt/custom/presets/contenta/1/stack_setup.hook.sh
#     cwt/custom/presets/contenta/1/stack_setup.docker-compose.hook.sh
#
#
# @example 2 : event + phase
#
#   PROJECT_STACK='drupal-8.4--p-contenta-1,redis,solr'
#   PROVISION_USING='docker-compose'
#   u_hook 'stack' 'init' 'post'
#
#   # Yields the following lookup paths :
#     cwt/app/stack/post_init.hook.sh
#     cwt/app/stack/docker-compose/post_init.hook.sh
#     cwt/app/stack_post_init.hook.sh
#     cwt/app/stack_post_init.docker-compose.hook.sh
#     cwt/env/stack/post_init.hook.sh
#     cwt/env/stack/docker-compose/post_init.hook.sh
#     cwt/env/stack_post_init.hook.sh
#     cwt/env/stack_post_init.docker-compose.hook.sh
#     cwt/git/stack/post_init.hook.sh
#     cwt/git/stack/docker-compose/post_init.hook.sh
#     cwt/git/stack_post_init.hook.sh
#     cwt/git/stack_post_init.docker-compose.hook.sh
#     cwt/provision/stack/post_init.hook.sh
#     cwt/provision/stack/docker-compose/post_init.hook.sh
#     cwt/provision/stack_post_init.hook.sh
#     cwt/provision/stack_post_init.docker-compose.hook.sh
#     cwt/remote/stack/post_init.hook.sh
#     cwt/remote/stack/docker-compose/post_init.hook.sh
#     cwt/remote/stack_post_init.hook.sh
#     cwt/remote/stack_post_init.docker-compose.hook.sh
#     cwt/stack/docker-compose.post_init.hook.sh
#     cwt/stack/docker-compose/post_init.hook.sh
#     cwt/app/presets/contenta/stack/post_init.hook.sh
#     cwt/app/presets/contenta/stack/docker-compose/post_init.hook.sh
#     cwt/app/presets/contenta/stack_post_init.hook.sh
#     cwt/app/presets/contenta/stack_post_init.docker-compose.hook.sh
#     cwt/app/presets/contenta/1/stack/post_init.hook.sh
#     cwt/app/presets/contenta/1/stack/docker-compose/post_init.hook.sh
#     cwt/app/presets/contenta/1/stack_post_init.hook.sh
#     cwt/app/presets/contenta/1/stack_post_init.docker-compose.hook.sh
#     cwt/env/presets/contenta/stack/post_init.hook.sh
#     cwt/env/presets/contenta/stack/docker-compose/post_init.hook.sh
#     cwt/env/presets/contenta/stack_post_init.hook.sh
#     cwt/env/presets/contenta/stack_post_init.docker-compose.hook.sh
#     cwt/env/presets/contenta/1/stack/post_init.hook.sh
#     cwt/env/presets/contenta/1/stack/docker-compose/post_init.hook.sh
#     cwt/env/presets/contenta/1/stack_post_init.hook.sh
#     cwt/env/presets/contenta/1/stack_post_init.docker-compose.hook.sh
#     cwt/git/presets/contenta/stack/post_init.hook.sh
#     cwt/git/presets/contenta/stack/docker-compose/post_init.hook.sh
#     cwt/git/presets/contenta/stack_post_init.hook.sh
#     cwt/git/presets/contenta/stack_post_init.docker-compose.hook.sh
#     cwt/git/presets/contenta/1/stack/post_init.hook.sh
#     cwt/git/presets/contenta/1/stack/docker-compose/post_init.hook.sh
#     cwt/git/presets/contenta/1/stack_post_init.hook.sh
#     cwt/git/presets/contenta/1/stack_post_init.docker-compose.hook.sh
#     cwt/provision/presets/contenta/stack/post_init.hook.sh
#     cwt/provision/presets/contenta/stack/docker-compose/post_init.hook.sh
#     cwt/provision/presets/contenta/stack_post_init.hook.sh
#     cwt/provision/presets/contenta/stack_post_init.docker-compose.hook.sh
#     cwt/provision/presets/contenta/1/stack/post_init.hook.sh
#     cwt/provision/presets/contenta/1/stack/docker-compose/post_init.hook.sh
#     cwt/provision/presets/contenta/1/stack_post_init.hook.sh
#     cwt/provision/presets/contenta/1/stack_post_init.docker-compose.hook.sh
#     cwt/remote/presets/contenta/stack/post_init.hook.sh
#     cwt/remote/presets/contenta/stack/docker-compose/post_init.hook.sh
#     cwt/remote/presets/contenta/stack_post_init.hook.sh
#     cwt/remote/presets/contenta/stack_post_init.docker-compose.hook.sh
#     cwt/remote/presets/contenta/1/stack/post_init.hook.sh
#     cwt/remote/presets/contenta/1/stack/docker-compose/post_init.hook.sh
#     cwt/remote/presets/contenta/1/stack_post_init.hook.sh
#     cwt/remote/presets/contenta/1/stack_post_init.docker-compose.hook.sh
#     cwt/stack/presets/contenta/stack/post_init.hook.sh
#     cwt/stack/presets/contenta/stack/docker-compose/post_init.hook.sh
#     cwt/stack/presets/contenta/stack_post_init.hook.sh
#     cwt/stack/presets/contenta/stack_post_init.docker-compose.hook.sh
#     cwt/stack/presets/contenta/1/stack/post_init.hook.sh
#     cwt/stack/presets/contenta/1/stack/docker-compose/post_init.hook.sh
#     cwt/stack/presets/contenta/1/stack_post_init.hook.sh
#     cwt/stack/presets/contenta/1/stack_post_init.docker-compose.hook.sh
#     cwt/custom/presets/contenta/stack/post_init.hook.sh
#     cwt/custom/presets/contenta/stack/docker-compose/post_init.hook.sh
#     cwt/custom/presets/contenta/stack_post_init.hook.sh
#     cwt/custom/presets/contenta/stack_post_init.docker-compose.hook.sh
#     cwt/custom/presets/contenta/1/stack/post_init.hook.sh
#     cwt/custom/presets/contenta/1/stack/docker-compose/post_init.hook.sh
#     cwt/custom/presets/contenta/1/stack_post_init.hook.sh
#     cwt/custom/presets/contenta/1/stack_post_init.docker-compose.hook.sh
#
u_hook() {
  local p_subject="$1"
  local p_event="$2"
  local p_phase="$3"
  local p_lookup_subjects="$4"

  local lookup_paths=()
  local lookup_subject=''
  local lookup_subjects='app env git provision remote stack'
  if [[ -n "$p_lookup_subjects" ]]; then
    lookup_subjects="$p_lookup_subjects"
  fi

  local stack_preset=''
  local sp_arr=()
  local sp_v=''
  local sp_path=''
  u_stack_get_presets "$PROJECT_STACK"

  # When hook is event only.
  if [[ -z "$p_phase" ]]; then
    for lookup_subject in $lookup_subjects; do
      if [[ "$lookup_subject" != "$p_subject" ]]; then
        u_hook_add_e_lookup_variants "cwt/$lookup_subject"
      else
        u_autoload_add_lookup_level "cwt/${p_subject}/" "${p_event}.hook.sh" "$PROVISION_USING" lookup_paths '' '/'
        u_autoload_add_lookup_level "cwt/${p_subject}/" "${p_event}.hook.sh" "$PROVISION_USING" lookup_paths
      fi
    done

    u_hook_add_presets_lookup_variants 'event_only'

  # When hook is event + phase.
  else
    for lookup_subject in $lookup_subjects; do

      if [[ "$lookup_subject" != "$p_subject" ]]; then
        u_hook_add_ep_lookup_variants "cwt/$lookup_subject"
      else
        u_autoload_add_lookup_level "cwt/${p_subject}/" "${p_phase}_${p_event}.hook.sh" "$PROVISION_USING" lookup_paths
        u_autoload_add_lookup_level "cwt/${p_subject}/" "${p_phase}_${p_event}.hook.sh" "$PROVISION_USING" lookup_paths '' '/'
      fi
    done

    u_hook_add_presets_lookup_variants 'event_phase'
  fi

  # Debug.
  if [[ $P_VERBOSE == 1 ]]; then
    u_autoload_print_lookup_paths lookup_paths "u_hook $p_subject $p_event $p_phase $p_lookup_subjects"
  fi

  local hook_script=''
  for hook_script in "${lookup_paths[@]}"; do
    if [[ -f "$hook_script" ]]; then
      eval $(u_autoload_override "$hook_script" 'continue')
      . "$hook_script"
    fi
    u_autoload_get_complement "$hook_script"
  done
}

##
# Adds event-only hook lookups variants.
#
# (internal lookups helper)
#
u_hook_add_e_lookup_variants() {
  local p_path="$1"

  lookup_paths+=("$p_path/${p_subject}/${p_event}.hook.sh")
  u_autoload_add_lookup_level "$p_path/${p_subject}/" "${p_event}.hook.sh" "$PROVISION_USING" lookup_paths '' '/'

  lookup_paths+=("$p_path/${p_subject}_${p_event}.hook.sh")
  u_autoload_add_lookup_level "$p_path/${p_subject}_${p_event}." "hook.sh" "$PROVISION_USING" lookup_paths
}

##
# Adds event + phase hook lookups variants.
#
# (internal lookups helper)
#
u_hook_add_ep_lookup_variants() {
  local p_path="$1"

  lookup_paths+=("$p_path/${p_subject}/${p_phase}_${p_event}.hook.sh")
  u_autoload_add_lookup_level "$p_path/${p_subject}/" "${p_phase}_${p_event}.hook.sh" "$PROVISION_USING" lookup_paths '' '/'

  lookup_paths+=("$p_path/${p_subject}_${p_phase}_${p_event}.hook.sh")
  u_autoload_add_lookup_level "$p_path/${p_subject}_${p_phase}_${p_event}." "hook.sh" "$PROVISION_USING" lookup_paths
}

##
# Adds presets-related hook lookups variants.
#
# (internal lookups helper)
#
u_hook_add_presets_lookup_variants() {
  local p_type="$1"

  for stack_preset in "${STACK_PRESETS[@]}"; do
    u_instance_item_split_version sp_arr "$stack_preset"

    if [[ -n "${sp_arr[1]}" ]]; then
      for lookup_subject in $lookup_subjects; do
        sp_path="cwt/${lookup_subject}/presets"
        for sp_v in "${sp_arr[@]}"; do
          sp_path+="/$sp_v"
          case "$p_type" in
            event_only)
              u_hook_add_e_lookup_variants "$sp_path" ;;
            event_phase)
              u_hook_add_ep_lookup_variants "$sp_path" ;;
          esac
        done
      done

      sp_path="$(u_autoload_get_custom_dir)/presets"
      for sp_v in "${sp_arr[@]}"; do
        sp_path+="/$sp_v"
        case "$p_type" in
          event_only)
            u_hook_add_e_lookup_variants "$sp_path" ;;
          event_phase)
            u_hook_add_ep_lookup_variants "$sp_path" ;;
        esac
      done

    else
      for lookup_subject in $lookup_subjects; do
        sp_path="cwt/${lookup_subject}/presets/$stack_preset"
        case "$p_type" in
          event_only)
            u_hook_add_e_lookup_variants "$sp_path" ;;
          event_phase)
            u_hook_add_ep_lookup_variants "$sp_path" ;;
        esac
      done

      sp_path="$(u_autoload_get_custom_dir)/presets/$stack_preset"
      case "$p_type" in
        event_only)
          u_hook_add_e_lookup_variants "$sp_path" ;;
        event_phase)
          u_hook_add_ep_lookup_variants "$sp_path" ;;
      esac
    fi
  done
}
