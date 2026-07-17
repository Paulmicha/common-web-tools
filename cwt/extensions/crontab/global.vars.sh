#!/usr/bin/env bash

##
# Global (env) vars for the crontab CWT extension.
#
# @see u_instance_init() in cwt/instance/instance.inc.sh
#

global CWT_CRON_SYNC_ON_INIT "[default]=false [help]='When true, post_init also runs host crontab sync after regenerating data/cwt/cron/*.sh.'"
