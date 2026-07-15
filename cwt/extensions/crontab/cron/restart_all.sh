#!/usr/bin/env bash

##
# Restart all enabled cron host entries (stop-all then sync).
#
# @example
#   make cron-restart-all
#

. cwt/bootstrap.sh

u_cron_require_crontab || exit 1
u_cron_crontab_write_block ''

if [[ ! -d scripts/cwt/local/cron ]]; then
  u_cron_settings_setup || exit 1
fi

u_cron_sync
echo "Restarted all enabled cron host lines."
