#!/bin/bash

##
# (Re)inits environment settings for this project intance.
#
# @see cwt/env/README.md
#
# Usage examples :
# $ . cwt/stack/init.sh                 # Will prompt to confirm/edit every default value
# $ . cwt/stack/init.sh -s drupal-7     # Short name/value argument syntax
# $ . cwt/stack/init.sh -s nodejs -y    # "-y" will use default values, no prompts
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

if [[ (-z "$PROJECT_STACK") && ($P_YES == 0) ]]; then
  read -p "Enter PROJECT_STACK value : " PROJECT_STACK
fi

if [[ -z "$PROJECT_STACK" ]]; then
  echo
  echo "Error in $BASH_SOURCE line $LINENO: cannot carry on without a value for \$PROJECT_STACK."
  echo "Aborting (1)."
  return 1
fi

# (Re)start dependencies and env vars aggregation.
unset ENV_VARS
declare -A ENV_VARS
ENV_VARS_COUNT=0
ENV_VARS_UNIQUE_NAMES=()
ENV_VARS_UNIQUE_KEYS=()

# Get CWT globals required for aggregating dependencies and env vars.
. cwt/env/vars.sh
u_exec_foreach_env_vars u_assign_env_value

# Aggregate dependencies and env vars.
. cwt/stack/init/aggregate_deps.sh
. cwt/stack/init/aggregate_env_vars.sh

# Write env vars in current instance's settings file.
. cwt/env/write.sh
