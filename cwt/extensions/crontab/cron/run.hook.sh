#!/usr/bin/env bash

##
# Implements hook -s 'cron' -a 'run'
#
# Default cron runner: honor CWT_CRON_* exports, apply wrap/lock, execute.
# @see cwt/extensions/crontab/cron/run.sh
#

u_cron_run_default() {
  local cmd
  local lock_mode="${CWT_CRON_LOCK:-skip}"
  local entry="${CWT_CRON_ENTRY:-}"
  local yml="data/threads/${entry}.yml"
  local run_id="${CWT_CRON_RUN:-}"

  # Thread-monitor style extras (optional).
  case "${CWT_CRON_MONITOR_MARK_STALE:-}" in true|TRUE|1)
    if [[ -f "$yml" ]] && u_thread_yml_load "$entry"; then
      if [[ "$thread_status" == 'running' ]] && ! kill -0 "$thread_pid" 2>/dev/null; then
        u_thread_yml_mark_stale
        echo "Marked stale: $entry (PID $thread_pid)"
      fi
    fi
  esac

  case "$run_id" in thread-monitor)
    case "${CWT_MONITORING:-1}" in 0|false|FALSE|off|OFF)
      echo "Cron thread-monitor: skipped (CWT_MONITORING=0)."
      return 0
      ;;
    esac
    case "${CWT_HOST_THREAD_MONITOR:-1}" in 0|false|FALSE|off|OFF)
      echo "Cron thread-monitor: skipped (CWT_HOST_THREAD_MONITOR=0)."
      return 0
      ;;
    esac
    u_hook_most_specific 'dry-run' -s 'thread' -a 'monitor' \
      -v 'STACK_VERSION PROVISION_USING HOST_TYPE HOST_OS'
    if [[ -n "${hook_most_specific_dry_run_match:-}" && -f "$hook_most_specific_dry_run_match" ]]; then
      # shellcheck disable=SC1090
      . "$hook_most_specific_dry_run_match"
    else
      echo >&2 "Error: no thread/monitor hook found."
      return 1
    fi
    return $?
    ;;
  esac

  # Pile-up: skip if thread still running.
  case "$lock_mode" in skip)
    if [[ -n "$entry" && -f "$yml" ]] && u_thread_yml_load "$entry"; then
      if [[ "$thread_status" == 'running' ]] && kill -0 "$thread_pid" 2>/dev/null; then
        echo "Cron skip: '$entry' already running (PID $thread_pid)."
        return 0
      fi
    fi
    ;;
  esac

  export CWT_WRAP_RETRY_MAX="${CWT_CRON_RETRY_MAX:-0}"
  export CWT_WRAP_RETRY_DELAY="${CWT_CRON_RETRY_DELAY:-10s}"
  export CWT_WRAP_NONINTERACTIVE=1
  export GIT_TERMINAL_PROMPT=0

  cmd="${CWT_CRON_CMD:-}"
  if [[ -z "$cmd" ]]; then
    echo >&2 "Error: CWT_CRON_CMD empty for entry '$entry'."
    return 1
  fi

  echo "Cron run: $cmd"
  eval "$cmd"
}

u_cron_run_default
