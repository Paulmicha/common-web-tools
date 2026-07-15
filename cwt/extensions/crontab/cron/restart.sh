#!/usr/bin/env bash

##
# Restart one cron host entry (stop then start/sync).
#
# @example
#   make cron-restart e:insta-save
#

. cwt/bootstrap.sh

p_entry="${1:-}"
if [[ -z "$p_entry" ]]; then
  echo >&2 "Error: e:<entry> required."
  exit 1
fi

u_cron_stop_entry "$p_entry"
u_cron_start_entry "$p_entry"
