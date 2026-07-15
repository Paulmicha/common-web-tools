#!/usr/bin/env bash

##
# Lists background threads started via cwt/thread/wrap.sh.
#
# @example
#   make thread-list
#   # Or :
#   cwt/thread/list.sh
#

. cwt/bootstrap.sh

u_thread_dir

if [[ ! -d "$thread_dir" ]]; then
  echo "No threads directory ($thread_dir)."

  exit 0
fi

shopt -s nullglob
yml_files=("$thread_dir"/*.yml)

if [[ ${#yml_files[@]} -eq 0 ]]; then
  echo "No thread YAML files in $thread_dir."

  exit 0
fi

printf '%-28s %-8s %-10s %-10s %-24s %-24s %s\n' \
  'ENTRY' 'PID' 'OWNER' 'STATUS' 'STARTED' 'LAST_UPDATE' 'OUTPUT'
printf '%-28s %-8s %-10s %-10s %-24s %-24s %s\n' \
  '----' '---' '-----' '------' '-------' '----------' '------'

for p_yml in "${yml_files[@]}"; do
  p_entry="${p_yml##*/}"
  p_entry="${p_entry%.yml}"

  unset thread_tree
  unset thread_entry thread_owner thread_pid thread_status
  unset thread_started_ms thread_output

  if ! u_thread_yml_load "$p_entry"; then
    continue
  fi

  if [[ "$thread_status" == 'running' ]] \
    && ! kill -0 "$thread_pid" 2>/dev/null; then
    u_thread_yml_mark_stale
  fi

  p_last='-'
  u_thread_output_mtime_ms "$thread_output" 'p_last'
  [[ -n "$p_last" ]] || p_last='-'

  printf '%-28s %-8s %-10s %-10s %-24s %-24s %s\n' \
    "$thread_entry" \
    "$thread_pid" \
    "$thread_owner" \
    "$thread_status" \
    "$thread_started_ms" \
    "$p_last" \
    "$thread_output"
done
