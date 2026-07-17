#!/usr/bin/env bash

##
# Gpt wrapper to wrapped scripts or make entry points.
#
# @param 1 String : make entry point name or path to wrapped script.
#
# @example
#   make gpt-wrap e:transcribe-all
#   # Or :
#   cwt/extensions/gpt/gpt/wrap.sh transcribe-all
#

. cwt/bootstrap.sh

p_script="$1"
shift

p_is_wrapper=0
gpt_file="$p_script"

if [[ "$p_script" == *'log/wrap.sh' ]]; then
  p_is_wrapper=1
  gpt_file="$1"
fi

# Restrict to make entry points, and convert scripts paths to entry points names.
make_entries=()
real_scripts=()
is_gpt_file_valid=0

u_make_list_entry_points

for index in "${!real_scripts[@]}"; do
  task="${make_entries[index]}"
  script="${real_scripts[index]}"

  case "$gpt_file" in "$script")
    gpt_file="${gpt_file/$script/$task}"
    is_gpt_file_valid=1
    continue
  esac

  if [[ $p_is_wrapper -eq 0 ]]; then
    case "$gpt_file" in "$task")
      p_script="$script"
      is_gpt_file_valid=1
    esac
  else
    case "$gpt_file" in "$task")
      is_gpt_file_valid=1
    esac
  fi
done

if [[ $is_gpt_file_valid -ne 1 ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO - only supports valid make entry points." >&2
  echo "Aborting (1)." >&2
  echo >&2
  exit 1
fi

p_entry="${gpt_file#e:}"
p_script_real="$(realpath -e "$p_script")"

# Refuse interactive-required scripts under wrap.
if grep -q '@requires interactive' "$p_script_real" 2>/dev/null; then
  echo >&2 "Error: '$p_entry' requires an interactive shell; refuse wrap."
  echo >&2 "Run in the foreground: make $p_entry"
  exit 1
fi

# Fast-fail @requires sudoing without root.
if grep -q '@requires sudoing' "$p_script_real" 2>/dev/null; then
  if [[ "$(id -u)" -ne 0 ]]; then
    echo >&2 "Error: '$p_entry' requires sudoing / root; refuse wrap as uid $(id -u)."
    echo >&2 "Example: sudo make lt e:$p_entry"
    exit 1
  fi
fi

p_args="$*"
p_owner="$(u_print_current_user)"
p_uid="$(id -u)"
p_euid="${EUID:-$p_uid}"
p_run_as="$(id -un)"
p_sudoing='false'
if [[ -n "${SUDO_USER:-}" ]] || [[ "$p_euid" -eq 0 && "$p_owner" != "$p_run_as" ]]; then
  p_sudoing='true'
fi
if [[ -n "${SUDO_USER:-}" ]]; then
  p_owner="$SUDO_USER"
fi

p_started_ms="$(date +%Y-%m-%dT%H:%M:%S.%3N)"
p_lock_mode="${CWT_THREAD_LOCK_MODE:-skip}"
p_retry_max="${CWT_WRAP_RETRY_MAX:-0}"
p_retry_delay="${CWT_WRAP_RETRY_DELAY:-10s}"
p_trigger="${CWT_THREAD_TRIGGER:-manual}"

if [[ -n "${CWT_LOG_WRAP_ACTIVE:-}" ]]; then
  p_output="data/logs/${p_entry}.txt"
else
  p_output='nohup.out'
fi

mkdir -p data/gpts

# Pile-up prevention (P1 + P5) via YAML/PID before backgrounding.
if u_gpt_pileup_should_skip "$p_entry"; then
  echo "Thread '$p_entry' already running (PID $gpt_pid); skip."
  exit 0
fi

export CWT_WRAP_NONINTERACTIVE=1
export GIT_TERMINAL_PROMPT=0

export CWT_THREAD_ENTRY="$p_entry"
export CWT_THREAD_OWNER="$p_owner"
export CWT_THREAD_UID="$p_uid"
export CWT_THREAD_EUID="$p_euid"
export CWT_THREAD_RUN_AS="$p_run_as"
export CWT_THREAD_SUDOING="$p_sudoing"
export CWT_THREAD_SCRIPT="$p_script_real"
export CWT_THREAD_ARGS="$p_args"
export CWT_THREAD_STARTED_MS="$p_started_ms"
export CWT_THREAD_OUTPUT="$p_output"
export CWT_THREAD_STATUS='running'
export CWT_THREAD_EXIT_CODE=''
export CWT_THREAD_ENDED_MS=''
export CWT_THREAD_MAX_ATTEMPTS="$p_retry_max"
export CWT_THREAD_LOCK_MODE="$p_lock_mode"
export CWT_THREAD_TRIGGER="$p_trigger"
export CWT_THREAD_NEEDS_INTERACTIVE='false'
export CWT_WRAP_EMITTER="${CWT_WRAP_EMITTER:-manual}"
export CWT_WRAP_RECEIVER="${CWT_WRAP_RECEIVER:-$p_entry}"
export CWT_WRAP_KIND="${CWT_WRAP_KIND:-gpt-wrap}"

# Supervisor writes YAML (start + EXIT) so short jobs cannot race the parent.
u_gpt_supervised_run() {
  trap 'u_gpt_supervisor_exit $?' EXIT

  if ! u_gpt_lock_acquire "$CWT_THREAD_ENTRY" "$p_lock_mode"; then
    echo "Thread '$CWT_THREAD_ENTRY' lock busy; skip."
    CWT_THREAD_STATUS='exited'
    CWT_THREAD_EXIT_CODE=0
    CWT_THREAD_ENDED_MS="$(date +%Y-%m-%dT%H:%M:%S.%3N)"
    # Avoid overwriting a running peer's YAML on skip.
    trap - EXIT
    exit 0
  fi

  export CWT_THREAD_PID="$BASHPID"
  export CWT_THREAD_PPID="$PPID"

  u_gpt_proc_tree "$BASHPID"
  export CWT_THREAD_TREE="$(printf '%s\n' "${gpt_tree[@]}")"

  local attempt=1
  local max_try=$((p_retry_max + 1))
  local delay_s
  local rc=0

  delay_s="$(u_gpt_delay_seconds "$p_retry_delay")"

  while true; do
    export CWT_THREAD_ATTEMPT="$attempt"
    u_gpt_yml_write "$CWT_THREAD_ENTRY"
    u_gpt_chown_human "data/gpts/${CWT_THREAD_ENTRY}.yml"

    # Noninteractive: no stdin (fail-fast on prompts).
    "$p_script_real" "$@" </dev/null
    rc=$?

    # Do not retry on SIGINT/SIGTERM-ish or success.
    if [[ $rc -eq 0 || $rc -eq 130 || $rc -eq 143 ]]; then
      return "$rc"
    fi

    if [[ $attempt -ge $max_try ]]; then
      return "$rc"
    fi

    echo "Thread retry $attempt/$p_retry_max after exit $rc (sleep ${delay_s}s) ..."
    sleep "$delay_s"
    attempt=$((attempt + 1))
  done
}

if [[ -n "${CWT_LOG_WRAP_ACTIVE:-}" ]]; then
  u_gpt_supervised_run "$@" &
else
  (
    trap '' HUP
    u_gpt_supervised_run "$@"
  ) >> "$p_output" 2>&1 </dev/null &
fi
p_pid=$!

# Brief wait so supervisor can create the YAML before we print its path.
sleep 0.05

u_gpt_chown_human "data/gpts/${p_entry}.yml"
u_gpt_chown_human "data/gpts/${p_entry}.lock"

echo "Thread started (PID $p_pid)."
echo "  script    : $p_script_real $*"
echo "  gpt    : data/gpts/${p_entry}.yml"
echo "  output    : $p_output"
