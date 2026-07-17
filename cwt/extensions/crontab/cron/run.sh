#!/usr/bin/env bash

##
# Run a scheduled crontab entry (host crontab invokes this).
#
# @example
#   make cron-run e:insta-save
#   cwt/extensions/crontab/cron/run.sh insta-save
#

. cwt/bootstrap.sh

p_entry="${1:-}"
p_entry="${p_entry#e:}"

if [[ -z "$p_entry" ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO - entry name required (e:<make-entry>)." >&2
  echo "Aborting (1)." >&2
  echo >&2
  exit 1
fi

if ! u_cron_entry_load "$p_entry"; then
  # Attempt regenerate once if missing.
  u_cron_settings_setup || true
  if ! u_cron_entry_load "$p_entry"; then
    echo >&2 "Error: no generated cron definition for '$p_entry'."
    echo >&2 "Add a {action}.{preset}.crontab.yml beside the entry script, then reinit."
    exit 1
  fi
fi

if [[ "${CWT_CRON_ENABLED}" != 'true' ]]; then
  echo "Cron entry '$p_entry' is disabled; skipping."
  exit 0
fi

u_hook_most_specific 'dry-run' -s 'cron' -a 'run' \
  -v 'STACK_VERSION PROVISION_USING HOST_TYPE HOST_OS'

if [[ ! -f "$hook_most_specific_dry_run_match" ]]; then
  echo >&2 "Error: no hook -s cron -a run implementation found."
  exit 1
fi

# shellcheck disable=SC1090
. "$hook_most_specific_dry_run_match"
