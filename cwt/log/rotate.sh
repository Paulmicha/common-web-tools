#!/usr/bin/env bash

##
# Rotates log files in data/logs when they exceed a size threshold.
#
# @param 1 [optional] String : make entry point name. Rotates all logs if omitted.
# @param 2 [optional] Number : max size in bytes (default: 1048576 = 1 MiB).
#
# @example
#   # All logs :
#   make log-rotate
#   # Or :
#   cwt/log/rotate.sh
#
#   # Filtered by make entry point :
#   make log-rotate e:transcribe-all
#   # Or :
#   cwt/log/rotate.sh transcribe-all
#

. cwt/bootstrap.sh

p_entry="$1"
p_max_bytes="${2:-1048576}"
log_dir='data/logs'

if [[ ! -d "$log_dir" ]]; then
  exit 0
fi

u_log_rotate_file() {
  local p_log_file="$1"
  local p_size=''

  if [[ ! -f "$p_log_file" ]]; then
    return 0
  fi

  p_size="$(stat -c '%s' "$p_log_file" 2>/dev/null || echo 0)"

  if [[ "$p_size" -lt "$p_max_bytes" ]]; then
    return 0
  fi

  p_rotated="${p_log_file}.1"

  if [[ -f "$p_rotated" ]]; then
    mv -f "$p_rotated" "${p_log_file}.2"
  fi

  mv -f "$p_log_file" "$p_rotated"
  touch "$p_log_file"

  echo "Rotated: $p_log_file -> $p_rotated (${p_size} bytes)"
}

if [[ -n "$p_entry" ]]; then
  p_entry=${p_entry#'e:'}
  u_log_rotate_file "${log_dir}/${p_entry}.txt"

  exit 0
fi

shopt -s nullglob
log_files=("$log_dir"/*.txt)

for p_log_file in "${log_files[@]}"; do
  case "$p_log_file" in
    *.changelog.txt) continue;;
  esac

  u_log_rotate_file "$p_log_file"
done
