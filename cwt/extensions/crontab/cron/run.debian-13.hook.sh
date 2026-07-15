#!/usr/bin/env bash

##
# Implements hook -s 'cron' -a 'run' for HOST_OS=debian-13.
#
# Same behavior as the default run hook (reserved for host-specific tweaks).
#

. cwt/extensions/crontab/cron/run.hook.sh
