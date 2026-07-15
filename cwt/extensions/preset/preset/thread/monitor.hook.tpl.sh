#!/usr/bin/env bash

##
# Implements hook -s 'thread' -a 'monitor'
#
# Host-level thread monitor sweep: mark stale, reclaim locks, heal sibling index
# under $HOME/.local/share/cwt/threads/. Gated by CWT_MONITORING / CWT_HOST_THREAD_MONITOR.
#
# This file is generated from template :
# @see {{ TEMPLATE }}
#
# @example
#   hook -s thread -a monitor
#

u_thread_monitor_enabled() {
  case "${CWT_MONITORING:-1}" in 0|false|FALSE|off|OFF) return 1 ;; esac
  case "${CWT_HOST_THREAD_MONITOR:-1}" in 0|false|FALSE|off|OFF) return 1 ;; esac
  return 0
}

u_thread_monitor_default() {
  local docroot
  local entry
  local yml
  local host_file
  local healed=0
  local marked=0

  if ! u_thread_monitor_enabled; then
    echo "thread-monitor: skipped (CWT_MONITORING / CWT_HOST_THREAD_MONITOR off)."
    return 0
  fi

  u_thread_host_index_dir
  mkdir -p "$thread_host_index_dir"

  # Heal / refresh from this instance's YAML records.
  if [[ -d data/threads ]]; then
    shopt -s nullglob
    for yml in data/threads/*.yml; do
      entry="${yml##*/}"
      entry="${entry%.yml}"
      if u_thread_yml_load "$entry"; then
        if [[ "$thread_status" == 'running' ]] && ! kill -0 "$thread_pid" 2>/dev/null; then
          u_thread_yml_mark_stale
          marked=$((marked + 1))
          echo "Marked stale: $entry (PID $thread_pid)"
        fi
        u_thread_host_publish "$entry"
        healed=$((healed + 1))
      fi
    done
    shopt -u nullglob
  fi

  # Drop host-index ghosts for this docroot whose YAML is gone or PID dead.
  docroot="${PROJECT_DOCROOT:-$(pwd)}"
  shopt -s nullglob
  for host_file in "$thread_host_index_dir"/*.yml; do
    unset thread_host_docroot thread_host_entry thread_host_pid thread_host_status
    # shellcheck disable=SC2034
    eval "$(u_yaml_parse "$host_file" 'thread_host_')" 2>/dev/null || true
    if [[ "${thread_host_docroot:-}" != "$docroot" ]]; then
      continue
    fi
    entry="${thread_host_entry:-}"
    if [[ -z "$entry" ]]; then
      continue
    fi
    if [[ ! -f "data/threads/${entry}.yml" ]]; then
      rm -f "$host_file"
      echo "Host index prune: $entry (no local YAML)"
      continue
    fi
    if [[ "${thread_host_status:-}" == 'running' ]] \
      && [[ -n "${thread_host_pid:-}" ]] \
      && ! kill -0 "$thread_host_pid" 2>/dev/null; then
      u_thread_yml_load "$entry" 2>/dev/null || true
      if [[ "${thread_status:-}" == 'running' ]]; then
        u_thread_yml_mark_stale 2>/dev/null || true
      fi
      u_thread_host_publish "$entry"
      echo "Host index heal: $entry (dead PID ${thread_host_pid})"
    fi
  done
  shopt -u nullglob

  echo "thread-monitor: refreshed=$healed marked_stale=$marked index=$thread_host_index_dir"
}

u_thread_monitor_default
