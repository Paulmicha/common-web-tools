#!/usr/bin/env bash

##
# Sync host crontab from generated definitions.
#
# @example
#   make cron-sync
#   make cron-sync e:insta-save
#

. cwt/bootstrap.sh

# Ensure generated defs exist.
if [[ ! -d data/cwt/cron ]] || [[ -z "$(echo data/cwt/cron/*.sh 2>/dev/null)" ]]; then
  u_cron_settings_setup || exit 1
fi

u_cron_sync "$@"
