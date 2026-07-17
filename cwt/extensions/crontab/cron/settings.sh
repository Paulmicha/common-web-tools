#!/usr/bin/env bash

##
# Dump effective crontab definitions (regenerates first).
#
# @example
#   make cron-settings
#

. cwt/bootstrap.sh

u_cron_settings_setup || exit 1

echo
echo "=== Effective crontab definitions ==="
echo

shopt -s nullglob
for f in data/cwt/cron/*.sh; do
  # shellcheck disable=SC1090
  . "$f"
  echo "entry      : $CWT_CRON_ENTRY"
  echo "  preset   : $CWT_CRON_PRESET"
  echo "  enabled  : $CWT_CRON_ENABLED"
  echo "  schedule : $CWT_CRON_SCHEDULE"
  echo "  wrap     : $CWT_CRON_WRAP"
  echo "  lock     : $CWT_CRON_LOCK"
  echo "  retry    : max=$CWT_CRON_RETRY_MAX delay=$CWT_CRON_RETRY_DELAY"
  echo "  cmd      : $CWT_CRON_CMD"
  echo "  source   : $CWT_CRON_SOURCE"
  echo
done
