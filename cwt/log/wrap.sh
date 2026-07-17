#!/usr/bin/env bash

##
# Log wrapper to run a make entry point in the background.
#
# Writes stdout + stderr to data/logs/{entrypoint}.txt and records each run
# in data/logs/{entrypoint}.changelog.txt.
#
# @param 1 String : path to wrapped script or make entry point name.
#
# @example
#   # This will write stdout + stderr to the following log file :
#   # data/logs/transcribe-all.txt
#   # And also add a new line in its corresponding "registry file" :
#   # data/logs/transcribe-all.changelog.txt
#   cwt/log/wrap.sh \
#     cwt/extensions/transcription/transcribe/all.sh
#
#   # Works with raw make entry points too :
#   make log-wrap e:test-cwt
#   # Or :
#   cwt/log/wrap.sh test-cwt
#
#   # Works with thread-wrap inner wrapper (log captures, thread backgrounds) :
#   make lt e:transcribe-all
#   # Or :
#   cwt/instance/logged_thread.sh transcribe-all
#   # Yields :
#   #   data/logs/transcribe-all.txt (+ changelog); PID in data/threads/
#   # Equivalent (without pre-process and post-process hooks) :
#   cwt/log/wrap.sh cwt/thread/wrap.sh transcribe-all
#

. cwt/bootstrap.sh

p_script="$1"
shift

log_file="$p_script"
uses_thread_inner_wrap=0
is_valid=0

if [[ "$p_script" == *'thread/wrap.sh' ]]; then
  uses_thread_inner_wrap=1
  log_file="$1"
fi

# Restrict to make entry points, and convert scripts paths to entry points names.
make_entries=()
real_scripts=()

u_make_list_entry_points

for index in "${!real_scripts[@]}"; do
  task="${make_entries[index]}"
  script="${real_scripts[index]}"

  # Convert script path to make entry point name.
  case "$log_file" in "$script")
    log_file="${log_file/$script/$task}"
    is_valid=1
    continue
  esac

  # Check other values against make entry points (whitelist).
  if [[ $uses_thread_inner_wrap -eq 0 ]]; then
    case "$log_file" in "$task")
      p_script="$script"
      is_valid=1
    esac
  else
    case "$log_file" in "$task")
      is_valid=1
    esac
  fi
done

if [[ $is_valid -ne 1 ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO - only supports valid make entry points." >&2
  echo "Aborting (1)." >&2
  echo >&2
  exit 1
fi

# Pile-up: do not truncate/restart logs if the entry thread is still running.
p_entry_name="${log_file#e:}"
if u_thread_pileup_should_skip "$p_entry_name"; then
  echo "Log/thread '$p_entry_name' already running (PID $thread_pid); skip."
  exit 0
fi

u_hook_most_specific 'dry-run' -s 'log' -a 'storage' -v 'STACK_VERSION PROVISION_USING HOST_TYPE HOST_OS'

if [[ ! -f "$hook_most_specific_dry_run_match" ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO - no implementation match :" >&2
  echo >&2
  echo "  u_hook_most_specific 'dry-run' -s 'log' -a 'storage' -v 'STACK_VERSION PROVISION_USING HOST_TYPE HOST_OS'" >&2
  echo >&2
  echo "    STACK_VERSION = '$HOST_OS'" >&2
  echo "    PROVISION_USING = '$PROVISION_USING'" >&2
  echo "    HOST_TYPE = '$HOST_TYPE'" >&2
  echo "    HOST_OS = '$HOST_OS'" >&2
  echo >&2
  echo "Aborting (1)." >&2
  echo >&2
  exit 1
fi

. "$hook_most_specific_dry_run_match" "$@"
