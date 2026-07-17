#!/usr/bin/env bash

##
# Implements hook -s 'log' -a 'storage'
#
# The following variables are available from calling scope here :
# @see cwt/log/wrap.sh
#
# - $log_file
# - $p_script
#

if [[ ! -d data/logs ]]; then
  mkdir -p data/logs
fi

# TODO support remote ids in log file names ?
# case "$1" in dev|local|lan|staging|preprod|prod)
#   log_file="$log_file.$1"
# esac

# Record whenever log file is (re)written.
log_file_changelog="data/logs/${log_file}.changelog.txt"

if [[ ! -f "$log_file_changelog" ]]; then
  touch "$log_file_changelog"
fi

datestamp="$(date +"%Y-%m-%dT%H:%M:%S.%3N")"
human_user="$(u_print_current_user)"
echo "$datestamp : $human_user (euid=$(id -u)) : $p_script $*" >> "$log_file_changelog"

# Write wrapped call outputs (2>&1) to the $log_file.
log_file="data/logs/${log_file}.txt"

export CWT_LOG_WRAP_ACTIVE=1
export CWT_WRAP_NONINTERACTIVE=1
export GIT_TERMINAL_PROMPT=0

# Noninteractive: close stdin so prompts fail fast instead of hanging.
nohup "$p_script" "$@" </dev/null > "$log_file" 2>&1 &
p_pid=$!

# Prefer human-owned artifacts when sudoing (S1).
if [[ -n "${SUDO_USER:-}" ]]; then
  chown "$SUDO_USER:" "$log_file" "$log_file_changelog" 2>/dev/null || true
  chown "$SUDO_USER:" data/logs 2>/dev/null || true
fi

echo "Log started (PID $p_pid)."
echo "  script    : $p_script $*"
echo "  output    : $log_file"
echo "  changelog : $log_file_changelog"
