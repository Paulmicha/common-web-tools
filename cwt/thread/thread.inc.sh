#!/usr/bin/env bash

##
# Thread-related utility functions.
#
# Eager subject include (CWT_INC / bootstrap phase 60) — must stay *.inc.sh.
# Used by thread actions and cross-subject callers (log/wrap pile-up, cron
# hooks); *.opt-inc.sh would not load for those callers.
# @see cwt/bootstrap.sh
# @see changelog/2026/07/16-cwt-opt-inc-eager-audit.md
#
# Convention : functions names are all prefixed by "u" (for "utility").
#

##
# Captures a compact process ancestry as "pid:comm" strings.
#
# Outputs in calling scope :
# @var thread_tree
#
# @param 1 String : starting PID.
# @param 2 [optional] Number : max depth (default 8).
#
u_thread_proc_tree() {
  local p_pid="$1"
  local p_max="${2:-8}"
  local cur="$p_pid"
  local depth=0
  local ppid
  local comm
  local stat_line

  thread_tree=()

  while [[ -n "$cur" && "$cur" -gt 0 && $depth -lt $p_max ]]; do
    if [[ ! -r "/proc/$cur/stat" ]]; then
      break
    fi

    stat_line="$(</proc/$cur/stat)"
    # comm is in parentheses and may contain spaces; PPID is after the closing ).
    comm="${stat_line#*(}"
    comm="${comm%%)*}"
    # After ')': state ppid ...
    read -r _ ppid _ <<< "${stat_line##*)}"

    thread_tree+=("${cur}:${comm}")

    if [[ -z "$ppid" || "$ppid" == "$cur" ]]; then
      break
    fi

    cur="$ppid"
    depth=$((depth + 1))
  done
}

##
# Writes (or overwrites) a thread lifecycle YAML file.
#
# Uses calling-scope / exported fields below when present, else empty string.
# Optional list : thread_tree (array of "pid:comm").
#
# @param 1 String : make entry point name.
#
# Expected scalar sources (first match wins) :
#   CWT_THREAD_* exports, or thread_* locals, for :
#   entry owner uid euid run_as sudoing script args pid ppid started_ms status
#   exit_code ended_ms output attempt max_attempts lock_mode trigger needs_interactive
#
u_thread_yml_write() {
  local p_entry="$1"
  local p_yml
  local y_keys
  declare -A y_sc=()

  p_yml="data/threads/${p_entry}.yml"
  mkdir -p data/threads

  y_sc[entry]="${CWT_THREAD_ENTRY:-${thread_entry:-$p_entry}}"
  y_sc[owner]="${CWT_THREAD_OWNER:-${thread_owner:-$(u_print_current_user)}}"
  y_sc[uid]="${CWT_THREAD_UID:-${thread_uid:-$(id -u)}}"
  y_sc[euid]="${CWT_THREAD_EUID:-${thread_euid:-${EUID:-$(id -u)}}}"
  y_sc[run_as]="${CWT_THREAD_RUN_AS:-${thread_run_as:-$(id -un)}}"
  y_sc[sudoing]="${CWT_THREAD_SUDOING:-${thread_sudoing:-false}}"
  y_sc[script]="${CWT_THREAD_SCRIPT:-${thread_script:-}}"
  y_sc[args]="${CWT_THREAD_ARGS:-${thread_args:-}}"
  y_sc[pid]="${CWT_THREAD_PID:-${thread_pid:-}}"
  y_sc[ppid]="${CWT_THREAD_PPID:-${thread_ppid:-}}"
  y_sc[started_ms]="${CWT_THREAD_STARTED_MS:-${thread_started_ms:-}}"
  y_sc[status]="${CWT_THREAD_STATUS:-${thread_status:-running}}"
  y_sc[exit_code]="${CWT_THREAD_EXIT_CODE:-${thread_exit_code:-}}"
  y_sc[ended_ms]="${CWT_THREAD_ENDED_MS:-${thread_ended_ms:-}}"
  y_sc[output]="${CWT_THREAD_OUTPUT:-${thread_output:-}}"
  y_sc[attempt]="${CWT_THREAD_ATTEMPT:-${thread_attempt:-}}"
  y_sc[max_attempts]="${CWT_THREAD_MAX_ATTEMPTS:-${thread_max_attempts:-}}"
  y_sc[lock_mode]="${CWT_THREAD_LOCK_MODE:-${thread_lock_mode:-skip}}"
  y_sc[trigger]="${CWT_THREAD_TRIGGER:-${thread_trigger:-manual}}"
  y_sc[needs_interactive]="${CWT_THREAD_NEEDS_INTERACTIVE:-${thread_needs_interactive:-false}}"

  y_keys=(
    entry owner uid euid run_as sudoing script args pid ppid started_ms status
    exit_code ended_ms output attempt max_attempts lock_mode trigger
    needs_interactive
  )

  if [[ ${#thread_tree[@]} -eq 0 && -n "${CWT_THREAD_TREE:-}" ]]; then
    mapfile -t thread_tree <<< "${CWT_THREAD_TREE}"
  fi

  if [[ ${#thread_tree[@]} -gt 0 ]]; then
    u_yaml_write "$p_yml" y_sc y_keys tree thread_tree
  else
    u_yaml_write "$p_yml" y_sc y_keys
  fi

  # Host sibling index (no-op when CWT_MONITORING / CWT_HOST_THREAD_MONITOR off).
  u_thread_host_publish "$p_entry"
}

##
# Loads a thread YAML record into thread_* variables (calling scope / shell).
#
# @param 1 String : make entry point name.
#
# @example
#   u_thread_yml_load 'transcribe-all'
#   echo "$thread_pid $thread_status"
#
u_thread_yml_load() {
  local p_entry="$1"
  local p_yml="data/threads/${p_entry}.yml"

  if [[ ! -f "$p_yml" ]]; then
    return 1
  fi

  # bash-yaml uses += for lists; clear before reload.
  unset thread_tree

  eval "$(u_yaml_parse "$p_yml" 'thread_')"
  u_thread_yml_strip_quotes
}

##
# Marks a loaded thread record as stale and rewrites its YAML.
#
# Requires a prior successful u_thread_yml_load (thread_* vars set).
# Strips yaml-parser quote artifacts before rewrite.
#
u_thread_yml_mark_stale() {
  local p_entry="${thread_entry:-}"

  if [[ -z "$p_entry" ]]; then
    return 1
  fi

  u_thread_yml_strip_quotes

  thread_status='stale'
  CWT_THREAD_ENTRY="$thread_entry"
  CWT_THREAD_OWNER="$thread_owner"
  CWT_THREAD_UID="$thread_uid"
  CWT_THREAD_EUID="${thread_euid:-}"
  CWT_THREAD_RUN_AS="${thread_run_as:-}"
  CWT_THREAD_SUDOING="${thread_sudoing:-false}"
  CWT_THREAD_SCRIPT="$thread_script"
  CWT_THREAD_ARGS="$thread_args"
  CWT_THREAD_PID="$thread_pid"
  CWT_THREAD_PPID="$thread_ppid"
  CWT_THREAD_STARTED_MS="$thread_started_ms"
  CWT_THREAD_STATUS='stale'
  CWT_THREAD_EXIT_CODE="${thread_exit_code:-}"
  CWT_THREAD_ENDED_MS="${thread_ended_ms:-}"
  CWT_THREAD_OUTPUT="${thread_output:-}"
  CWT_THREAD_ATTEMPT="${thread_attempt:-}"
  CWT_THREAD_MAX_ATTEMPTS="${thread_max_attempts:-}"
  CWT_THREAD_LOCK_MODE="${thread_lock_mode:-skip}"
  CWT_THREAD_TRIGGER="${thread_trigger:-manual}"
  CWT_THREAD_NEEDS_INTERACTIVE="${thread_needs_interactive:-false}"

  if [[ ${#thread_tree[@]} -gt 0 ]]; then
    CWT_THREAD_TREE="$(printf '%s\n' "${thread_tree[@]}")"
  fi

  u_thread_yml_write "$p_entry"
}

##
# Strip surrounding quotes left on scalars by bash-yaml parse round-trips.
#
u_thread_yml_strip_quotes() {
  local _v
  local _k

  for _k in entry owner uid euid run_as sudoing script args pid ppid started_ms \
    status exit_code ended_ms output attempt max_attempts lock_mode trigger \
    needs_interactive; do
    _v="thread_${_k}"
    if [[ -n "${!_v:-}" ]]; then
      printf -v "$_v" '%s' "${!_v#\"}"
      printf -v "$_v" '%s' "${!_v%\"}"
    fi
  done

  if [[ ${#thread_tree[@]} -gt 0 ]]; then
    local i
    for i in "${!thread_tree[@]}"; do
      thread_tree[$i]="${thread_tree[$i]#\"}"
      thread_tree[$i]="${thread_tree[$i]%\"}"
    done
  fi
}

##
# EXIT trap for supervised thread jobs — writes final status to YAML.
#
# Relies on CWT_THREAD_* exports set by the supervisor before the wrapped
# script runs (same subshell). Does not reload YAML (avoids quote round-trips).
#
# @param 1 Number : exit code of the wrapped script.
#
u_thread_supervisor_exit() {
  local p_rc="$1"

  CWT_THREAD_STATUS='exited'
  CWT_THREAD_EXIT_CODE="$p_rc"
  CWT_THREAD_ENDED_MS="$(date +%Y-%m-%dT%H:%M:%S.%3N)"

  # Common "needs TTY / interactive input" signals.
  case "$p_rc" in
    75|126|130)
      CWT_THREAD_NEEDS_INTERACTIVE='true'
      ;;
  esac

  if [[ -n "${CWT_THREAD_TREE:-}" ]]; then
    mapfile -t thread_tree <<< "${CWT_THREAD_TREE}"
  fi

  u_thread_yml_write "${CWT_THREAD_ENTRY}"

  # Release flock if held on fd 9.
  if { true >&9; } 2>/dev/null; then
    flock -u 9 2>/dev/null || true
  fi
}

##
# Chown path to invoking human when sudoing (S1).
#
u_thread_chown_human() {
  local p_path="$1"

  if [[ ! -e "$p_path" ]]; then
    return 0
  fi

  if [[ -n "${SUDO_USER:-}" ]]; then
    chown "$SUDO_USER:" "$p_path" 2>/dev/null || true
  fi
}

##
# Pile-up check: return 0 if safe to start, 1 if should skip (already running).
#
u_thread_pileup_should_skip() {
  local p_entry="$1"
  local yml="data/threads/${p_entry}.yml"

  if [[ ! -f "$yml" ]]; then
    return 1
  fi

  if ! u_thread_yml_load "$p_entry"; then
    return 1
  fi

  if [[ "$thread_status" == 'running' ]]; then
    if kill -0 "$thread_pid" 2>/dev/null; then
      return 0
    fi
    u_thread_yml_mark_stale
  fi

  return 1
}

##
# Acquire non-blocking flock for entry; skip/wait per lock mode.
#
# Uses fd 9. Returns 0 on lock acquired, 1 on skip.
#
u_thread_lock_acquire() {
  local p_entry="$1"
  local p_mode="${2:-skip}"
  local lock="data/threads/${p_entry}.lock"

  mkdir -p data/threads
  eval "exec 9>\"$lock\""
  u_thread_chown_human "$lock"

  case "$p_mode" in
    wait)
      flock 9 || return 1
      ;;
    *)
      if ! flock -n 9; then
        return 1
      fi
      ;;
  esac

  return 0
}

##
# Parse delay like 10s / 2m into integer seconds (echo).
#
u_thread_delay_seconds() {
  local d="${1:-10s}"
  if [[ "$d" =~ ^([0-9]+)s$ ]]; then
    echo "${BASH_REMATCH[1]}"
  elif [[ "$d" =~ ^([0-9]+)m$ ]]; then
    echo $((BASH_REMATCH[1] * 60))
  elif [[ "$d" =~ ^([0-9]+)h$ ]]; then
    echo $((BASH_REMATCH[1] * 3600))
  elif [[ "$d" =~ ^[0-9]+$ ]]; then
    echo "$d"
  else
    echo 10
  fi
}

##
# Last modification time of a file (ISO ms), or empty if missing.
#
# NB : for performance reasons (to avoid using a subshell), this function
# writes its result to a variable subject to collision in calling scope.
# The default variable name is overridable : see arg 2.
#
# @param 1 String : file path.
# @param 2 [optional] String : variable name in calling scope for the result.
#   Defaults to : 'thread_output_mtime_ms'.
#
# @example
#   u_thread_output_mtime_ms 'data/logs/foo.txt'
#   echo "$thread_output_mtime_ms"
#
u_thread_output_mtime_ms() {
  local p_file="$1"
  local p_var_name="$2"

  if [[ -z "$p_var_name" ]]; then
    p_var_name='thread_output_mtime_ms'
  fi

  if [[ ! -f "$p_file" ]]; then
    printf -v "$p_var_name" '%s' ''
    return 1
  fi

  printf -v "$p_var_name" '%s' \
    "$(date -r "$p_file" '+%Y-%m-%dT%H:%M:%S.%3N' 2>/dev/null || true)"
}

##
# Host sibling index directory ($HOME/.local/share/cwt/threads).
#
# Writes thread_host_index_dir in calling scope.
#
u_thread_host_index_dir() {
  local home="${HOME:-}"
  if [[ -z "$home" ]]; then
    home="$(getent passwd "${SUDO_USER:-$(id -un)}" 2>/dev/null | cut -d: -f6 || true)"
  fi
  if [[ -z "$home" ]]; then
    home='/tmp'
  fi
  thread_host_index_dir="${home}/.local/share/cwt/threads"
}

##
# True when host thread monitoring / publish is enabled.
#
u_thread_host_monitor_enabled() {
  case "${CWT_MONITORING:-1}" in 0|false|FALSE|off|OFF) return 1 ;; esac
  case "${CWT_HOST_THREAD_MONITOR:-1}" in 0|false|FALSE|off|OFF) return 1 ;; esac
  return 0
}

##
# Publish (or update) one entry in the host sibling index.
#
# Safe no-op when monitoring env gates are off. Filename encodes a stable hash
# of docroot+entry so nested instances do not collide.
#
# @param 1 String : make entry name.
#
u_thread_host_publish() {
  local p_entry="$1"
  local docroot
  local slug
  local host_file
  local y_keys
  declare -A y_sc=()

  if [[ -z "$p_entry" ]]; then
    return 1
  fi

  if ! u_thread_host_monitor_enabled; then
    return 0
  fi

  docroot="${PROJECT_DOCROOT:-$(pwd)}"
  u_thread_host_index_dir
  mkdir -p "$thread_host_index_dir"

  slug="$(printf '%s\n' "${docroot}::${p_entry}" | sha256sum | awk '{print $1}')"
  slug="${slug:0:16}"
  host_file="${thread_host_index_dir}/${slug}.yml"

  y_sc[docroot]="$docroot"
  y_sc[entry]="${CWT_THREAD_ENTRY:-$p_entry}"
  y_sc[pid]="${CWT_THREAD_PID:-${thread_pid:-}}"
  y_sc[status]="${CWT_THREAD_STATUS:-${thread_status:-}}"
  y_sc[owner]="${CWT_THREAD_OWNER:-${thread_owner:-}}"
  y_sc[mtime]="$(date +%Y-%m-%dT%H:%M:%S.%3N)"
  y_sc[trigger]="${CWT_THREAD_TRIGGER:-${thread_trigger:-manual}}"
  y_keys=(docroot entry pid status owner mtime trigger)

  u_yaml_write "$host_file" y_sc y_keys
}

##
# Composition helpers: parse e:/a:/join:/workers: and run sequence / batch / pipe.
#
# Shared calling-scope outputs (parsers) :
#   thread_join, thread_max_workers
#   thread_entries[], thread_entry_args[]   (args are printf-%q encoded)
#   thread_stage_kind[], thread_stage_value[], thread_stage_args[]  (pipe)
#

##
# Appends one printf-%q encoded arg to thread_entry_args[idx] (or stage args).
#
u_thread_args_append() {
  local p_arr_name="$1"
  local p_idx="$2"
  local p_val="$3"
  local enc
  local -n _u_ta_ref="$p_arr_name"

  printf -v enc '%q' "$p_val"
  if [[ -n "${_u_ta_ref[$p_idx]}" ]]; then
    _u_ta_ref[$p_idx]+=" $enc"
  else
    _u_ta_ref[$p_idx]="$enc"
  fi
}

##
# Runs: make <entry> [decoded args…]
#
# @param 1 String : make entry.
# @param 2 String : printf-%q encoded args (may be empty).
#
u_thread_run_make_step() {
  local p_entry="$1"
  local p_encoded="$2"
  local -a args=()
  local found=0
  local e=''

  # Reject unknown entries: Makefile has a silent catch-all (%:) that would
  # otherwise make missing goals look successful.
  if [[ -f data/cwt/cache/make.sh ]]; then
    # Fresh arrays (cache uses +=).
    make_entries=()
    real_scripts=()
    . data/cwt/cache/make.sh
    for e in "${make_entries[@]}"; do
      if [[ "$e" == "$p_entry" ]]; then
        found=1
        break
      fi
    done
    if [[ $found -ne 1 ]]; then
      echo >&2 "Error: unknown make entry '$p_entry'."
      return 127
    fi
  fi

  if [[ -n "$p_encoded" ]]; then
    # shellcheck disable=SC2086
    eval "args=($p_encoded)"
  fi

  make "$p_entry" "${args[@]}"
}

##
# Parses sequence/batch argv into thread_entries / thread_entry_args + kwargs.
#
# Accepts: e:<entry>, e:<N>:<entry>, a:<arg>, join:&&|;, workers:<N>
# Bare tokens (no known prefix) are treated as entry names (compat).
#
# @return 1 on parse error (e.g. a: before any e:).
#
u_thread_parse_e_args() {
  thread_join="${CWT_THREAD_JOIN:-&&}"
  thread_max_workers="${CWT_THREAD_MAX_WORKERS:-4}"
  thread_entries=()
  thread_entry_args=()

  local arg=''
  local entry=''
  local rest=''
  local current=-1

  for arg in "$@"; do
    case "$arg" in
      join:*)
        thread_join="${arg#join:}"
        ;;
      workers:*)
        thread_max_workers="${arg#workers:}"
        ;;
      a:*)
        if [[ $current -lt 0 ]]; then
          echo >&2 "Error: a: arg before any e: entry ($arg)."
          return 1
        fi
        u_thread_args_append thread_entry_args "$current" "${arg#a:}"
        ;;
      e:*)
        rest="${arg#e:}"
        case "$rest" in
          [0-9]*:*)
            entry="${rest#*:}"
            ;;
          *)
            entry="$rest"
            ;;
        esac
        if [[ -z "$entry" ]]; then
          echo >&2 "Error: empty e: entry ($arg)."
          return 1
        fi
        thread_entries+=("$entry")
        thread_entry_args+=('')
        current=$((${#thread_entries[@]} - 1))
        ;;
      *)
        # Bare make entry (compat with older batch/sequence call sites).
        thread_entries+=("$arg")
        thread_entry_args+=('')
        current=$((${#thread_entries[@]} - 1))
        ;;
    esac
  done

  if [[ ${#thread_entries[@]} -eq 0 ]]; then
    echo >&2 "Error: at least one e:<entry> (or bare entry) is required."
    return 1
  fi

  case "$thread_join" in
    '&&'|';') ;;
    *)
      echo >&2 "Error: invalid join:'$thread_join' (use && or ;)."
      return 1
      ;;
  esac

  if [[ ! "$thread_max_workers" =~ ^[0-9]+$ ]]; then
    echo >&2 "Error: workers must be a number (got '$thread_max_workers')."
    return 1
  fi
  if (( thread_max_workers < 1 )); then
    thread_max_workers=1
  elif (( thread_max_workers > 32 )); then
    thread_max_workers=32
  fi

  return 0
}

##
# Parses pipe argv: shell strings and/or e:/a: make stages.
#
# @var thread_stage_kind[]  make|shell
# @var thread_stage_value[] entry or shell command string
# @var thread_stage_args[]  encoded make args
#
# @return 1 on parse error.
#
u_thread_parse_pipe_stages() {
  thread_stage_kind=()
  thread_stage_value=()
  thread_stage_args=()

  local arg=''
  local entry=''
  local rest=''
  local current=-1

  for arg in "$@"; do
    case "$arg" in
      a:*)
        if [[ $current -lt 0 ]]; then
          echo >&2 "Error: a: before any pipe stage ($arg)."
          return 1
        fi
        if [[ "${thread_stage_kind[$current]}" != 'make' ]]; then
          echo >&2 "Error: a: only applies to make stages ($arg)."
          return 1
        fi
        u_thread_args_append thread_stage_args "$current" "${arg#a:}"
        ;;
      e:*)
        rest="${arg#e:}"
        case "$rest" in
          [0-9]*:*) entry="${rest#*:}" ;;
          *) entry="$rest" ;;
        esac
        if [[ -z "$entry" ]]; then
          echo >&2 "Error: empty e: entry ($arg)."
          return 1
        fi
        thread_stage_kind+=('make')
        thread_stage_value+=("$entry")
        thread_stage_args+=('')
        current=$((${#thread_stage_kind[@]} - 1))
        ;;
      join:*|workers:*)
        echo >&2 "Error: $arg is not valid for pipe (use sequence/batch)."
        return 1
        ;;
      *)
        # Positional shell stage.
        thread_stage_kind+=('shell')
        thread_stage_value+=("$arg")
        thread_stage_args+=('')
        current=$((${#thread_stage_kind[@]} - 1))
        ;;
    esac
  done

  if (( ${#thread_stage_kind[@]} < 2 )); then
    echo >&2 "Error: pipe requires at least 2 stages."
    return 1
  fi

  return 0
}

##
# Runs parsed sequence (thread_entries) with join && or ;.
#
# @return step rc (&& fail-fast) or worst nonzero (;).
#
u_thread_run_sequence() {
  local i
  local rc=0
  local worst=0

  for i in "${!thread_entries[@]}"; do
    u_thread_run_make_step "${thread_entries[$i]}" "${thread_entry_args[$i]}"
    rc=$?
    if (( rc == 0 )); then
      continue
    fi
    if [[ "$thread_join" == '&&' ]]; then
      return "$rc"
    fi
    if (( rc > worst )); then
      worst=$rc
    fi
  done

  return "$worst"
}

##
# Runs parsed batch with wave barriers (thread_max_workers) and wait; exit worst.
#
u_thread_run_batch() {
  local i=0
  local n=${#thread_entries[@]}
  local workers=$thread_max_workers
  local worst=0
  local w
  local pid
  local brc
  local -a pids=()

  if (( workers < 1 )); then workers=1; fi
  if (( workers > 32 )); then workers=32; fi

  while (( i < n )); do
    pids=()
    w=0
    while (( i < n && w < workers )); do
      (
        u_thread_run_make_step "${thread_entries[$i]}" "${thread_entry_args[$i]}"
      ) &
      pids+=($!)
      i=$((i + 1))
      w=$((w + 1))
    done
    for pid in "${pids[@]}"; do
      wait "$pid"
      brc=$?
      if (( brc == 0 )); then
        continue
      fi
      if (( brc > worst )); then
        worst=$brc
      fi
    done
  done

  return "$worst"
}

##
# Runs parsed pipe stages under pipefail.
#
u_thread_run_pipe() {
  local i
  local n=${#thread_stage_kind[@]}
  local cmd=''
  local part=''
  local qentry=''

  set -o pipefail

  for ((i = 0; i < n; i++)); do
    if [[ "${thread_stage_kind[$i]}" == 'make' ]]; then
      printf -v qentry '%q' "${thread_stage_value[$i]}"
      part="make $qentry"
      if [[ -n "${thread_stage_args[$i]}" ]]; then
        part+=" ${thread_stage_args[$i]}"
      fi
    else
      printf -v qentry '%q' "${thread_stage_value[$i]}"
      part="bash -c -- $qentry"
    fi
    if [[ -n "$cmd" ]]; then
      cmd+=' | '
    fi
    cmd+="{ $part ; }"
  done

  eval "$cmd"
}
