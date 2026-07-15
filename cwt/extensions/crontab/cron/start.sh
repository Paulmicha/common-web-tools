#!/usr/bin/env bash

##
# Install/sync host crontab including given entry (full enabled set).
#
# @example
#   make cron-start e:insta-save
#

. cwt/bootstrap.sh

p_entry="${1:-}"
if [[ -z "$p_entry" ]]; then
  echo >&2 "Error: e:<entry> required."
  exit 1
fi

if [[ ! -d scripts/cwt/local/cron ]]; then
  u_cron_settings_setup || exit 1
fi

u_cron_start_entry "$p_entry"
