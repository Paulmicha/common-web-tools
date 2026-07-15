#!/usr/bin/env bash

##
# Implements hook -s 'loop' -a 'monitor'
#
# Instance-level loop unit health check (active/failed/inactive, stale hints).
# Gated by CWT_MONITORING / CWT_LOOP_MONITOR.
#
# This file is generated from template :
# @see {{ TEMPLATE }}
#
# @param 1 [optional] String : loop instance id (default: all in registry).
#

u_loop_monitor_enabled() {
  case "${CWT_MONITORING:-1}" in 0|false|FALSE|off|OFF) return 1 ;; esac
  case "${CWT_LOOP_MONITOR:-1}" in 0|false|FALSE|off|OFF) return 1 ;; esac
  return 0
}

u_loop_monitor_one() {
  local p_id="$1"
  local reg="scripts/cwt/local/loop/${p_id}.sh"
  local unit=''
  local state=''

  if [[ ! -f "$reg" ]]; then
    echo "loop-monitor: no registry for '$p_id'"
    return 1
  fi

  # shellcheck disable=SC1090
  . "$reg"
  unit="${CWT_LOOP_UNIT:-}"
  if [[ -z "$unit" ]]; then
    echo "loop-monitor: empty unit for '$p_id'"
    return 1
  fi

  state="$(systemctl --user is-active "$unit" 2>/dev/null || echo unknown)"
  printf '%-40s %-12s %s\n' "$p_id" "$state" "$unit"
}

u_loop_monitor_default() {
  local p_filter="${1:-}"
  local f
  local id

  if ! u_loop_monitor_enabled; then
    echo "loop-monitor: skipped (CWT_MONITORING / CWT_LOOP_MONITOR off)."
    return 0
  fi

  if [[ -n "$p_filter" ]]; then
    p_filter="${p_filter#e:}"
    u_loop_monitor_one "$p_filter"
    return $?
  fi

  if [[ ! -d scripts/cwt/local/loop ]]; then
    echo "loop-monitor: no registry dir."
    return 0
  fi

  printf '%-40s %-12s %s\n' 'INSTANCE' 'STATE' 'UNIT'
  shopt -s nullglob
  for f in scripts/cwt/local/loop/*.sh; do
    id="${f##*/}"
    id="${id%.sh}"
    u_loop_monitor_one "$id"
  done
  shopt -u nullglob
}

u_loop_monitor_default "$@"
