#!/bin/bash

##
# Hooks-related utility functions.
#
# TODO evaluate using a more generic function that could be "wrapped" by others
# to achieve different types of lookups, e.g. :
# - u_hook() could act as a base function dealing with variation-related params (like currently $p_lookup_subjects)
# - u_hook_app() already provides lookups specific to current app and its version
# - u_hook_cwt() [proposition] for "internal" triggers (related to CWT, like stack/post-init)
#
# This file is dynamically loaded.
# @see cwt/bash_utils.sh
#
# Convention : functions names are all prefixed by "u" (for "utility").
#

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
#   u_hook_app_call 'apply' 'ownership_and_perms'
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
u_hook_app_call() {
  if [[ -z "$APP" ]]; then
    u_stack_get_specs "$PROJECT_STACK"
  fi

  local lookup_subjects="app app/$APP"
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

  u_hook_call "$1" "$2" "$3" "$lookup_subjects"
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
#   u_hook_call 'stack' 'setup'
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
#   u_hook_call 'stack' 'init' 'post'
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
u_hook_call() {
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
    u_autoload_print_lookup_paths lookup_paths "u_hook_call $p_subject $p_event $p_phase $p_lookup_subjects"
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
    u_env_item_split_version sp_arr "$stack_preset"

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
