#!/usr/bin/env bash

##
# Remove host crontab lines for one entry (YAML def kept).
#
# @example
#   make cron-stop e:insta-save
#

. cwt/bootstrap.sh

p_entry="${1:-}"
if [[ -z "$p_entry" ]]; then
  echo >&2 "Error: e:<entry> required."
  exit 1
fi

u_cron_stop_entry "$p_entry"
