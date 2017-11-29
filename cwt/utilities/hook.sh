#!/bin/bash

##
# Hooks-related utility functions.
#
# This file is dynamically loaded.
# @see cwt/bash_utils.sh
#
# Convention : functions names are all prefixed by "u" (for "utility").
#

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
#
# @example 1 : event only
#
#   u_hook_call stack setup
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
#
#
# @example 2 : event + phase
#
#   u_hook_call stack init post
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
#
u_hook_call() {
  local p_subject="$1"
  local p_event="$2"
  local p_phase="$3"

  local lookup_paths=()
  local lookup_subject=''
  local lookup_subjects='app env git provision remote stack'

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
  u_autoload_print_lookup_paths lookup_paths "u_hook_call $p_subject $p_event $p_phase"

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
          # u_hook_add_e_lookup_variants "$sp_path"

          case "$p_type" in
            event_only)
              u_hook_add_e_lookup_variants "$sp_path" ;;
            event_phase)
              u_hook_add_ep_lookup_variants "$sp_path" ;;
          esac
        done
      done

      sp_path="cwt/custom/presets"
      for sp_v in "${sp_arr[@]}"; do
        sp_path+="/$sp_v"
        # u_hook_add_e_lookup_variants "$sp_path"
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
        # u_hook_add_e_lookup_variants "$sp_path"
        case "$p_type" in
          event_only)
            u_hook_add_e_lookup_variants "$sp_path" ;;
          event_phase)
            u_hook_add_ep_lookup_variants "$sp_path" ;;
        esac
      done
    fi
  done
}
