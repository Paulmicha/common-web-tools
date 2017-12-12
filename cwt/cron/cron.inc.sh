#!/usr/bin/env bash

##
# Cron-related utility functions.
#
# This file is dynamically loaded.
# @see cwt/bootstrap.sh
#
# Convention : functions names are all prefixed by "u" (for "utility").
#

##
# Adds (once) a cronjob on local host.
#
# @requires the 'crontab' software.
# See https://stackoverflow.com/a/17975418
#
# @param 1 String the shell command to run.
# @param 2 [optional] String crontab time - defaults to "every 30 minutes" which
#   is noted like : */30 * * * *
#
# Quick crontab syntax notes :
#
#   * * * * *
#   | | | | |
#   | | | | +----- day of week (0 - 6) (Sunday=0)
#   | | | +------- month (1 - 12)
#   | | +--------- day of month (1 - 31)
#   | +----------- hour (0 - 23)
#   +------------- min (0 - 59)
#
# Numbers like 10 mean "at the 10th ..." (depending on position above).
# Fractions like "0/5" mean "every 5 ..." (depending on position above).
#
# @example
#   # Run drupal cron task every 20 minutes :
#   u_cron_add "drush --root=$APP_DOCROOT cron" "*/20 * * * *"
#
u_cron_add() {
  local p_cmd="$1"
  local p_freq="$2"

  if [[ -z "$p_freq" ]]; then
    p_freq="*/30 * * * *"
  fi

  local cronjob="$p_freq $p_cmd"

  # See https://stackoverflow.com/a/17975418
  ( crontab -l | grep -v -F "$p_cmd" ; echo "$cronjob" ) | crontab -
}
