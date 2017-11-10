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
. cwt/stack/init/get_args.sh

# These globals are needed throughout this task's related scripts.
export ENV_VARS
export ENV_VARS_COUNT
export ENV_VARS_UNIQUE_NAMES
export ENV_VARS_UNIQUE_KEYS

export PROJECT_STACK="$P_PROJECT_STACK"
export PROVISION_USING="$P_PROVISION_USING"
export CURRENT_ENV_SETTINGS_FILE='cwt/env/current/vars.sh'

# For now, we consider that it's possible to use return in main shell scope to
# stop the whole script immediately.
# We are evaluating the recommended pattern to wrap everything inside a main()
# function instead, used as the single entry point for a given task.
if [[ -z "$PROJECT_STACK" ]]; then
  echo "Warning in $BASH_SOURCE line $LINENO: cannot carry on without a value for \$P_PROJECT_STACK."
  return
fi

# This default value is required before env vars aggregation, so it's hardcoded.
# TODO : not necessary - see cwt/stack/init/aggregate_env_vars.sh
if [[ -z "$PROVISION_USING" ]]; then
  PROVISION_USING='scripts'
fi

# Arguments matching + default value fallback.
. cwt/stack/init/match_args_w_env_vars.sh

# (Re)start env vars aggregation.
unset ENV_VARS
declare -A ENV_VARS
ENV_VARS_COUNT=0
ENV_VARS_UNIQUE_NAMES=()
ENV_VARS_UNIQUE_KEYS=()
. cwt/stack/init/aggregate_env_vars.sh

# Write env vars in current instance's settings file.
. cwt/env/write.sh
