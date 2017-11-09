#!/bin/bash

##
# [wip] Init environment settings for this project intance.
#
# Prerequisites:
# Local Git repo initialized. See main README.md - section "Usage".
#
# This script will dynamically generate and (over)write settings based on
# the following values :
# 1. type of storage to use for CWT env settings on current host
# 2. provisioning method
# 3. project stack
# 4. instance type
# 5. instance domain
# 6. [wip] deploy method
# 7. [wip] testing (preset)
#
# Usage examples :
# $ . cwt/stack/init.sh                 # Will prompt to confirm/edit every default value
# $ . cwt/stack/init.sh -y              # Will use default values
# $ . cwt/stack/init.sh -s drupal-7     # Short name/value argument syntax
# $ . cwt/stack/init.sh --stack=drupal-7 --yes      # Longer name/value argument syntax (equivalent)
#

. cwt/bash_utils.sh

# Get named script arguments.
. cwt/stack/init/arguments.sh

# These values are needed throughout this task's related scripts.
export ENV_VARS
export PROJECT_STACK="$P_PROJECT_STACK"
export CURRENT_ENV_SETTINGS_FILE='cwt/env/current/vars.sh'

if [[ -z "$PROJECT_STACK" ]]; then
  echo "Warning in $BASH_SOURCE line $LINENO: cannot carry on without a value for \$P_PROJECT_STACK."
  return
fi

# Arguments matching + default value fallback.
# WIP / TODO
. cwt/stack/init/match_args_w_env_vars.sh

# Aggregates env vars.
declare -A ENV_VARS
. cwt/stack/init/aggregate_env_vars.sh

# Write in current instance env settings file.
# WIP / TODO
. cwt/env/write.sh
