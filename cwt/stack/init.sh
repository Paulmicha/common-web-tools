#!/usr/bin/env bash

##
# (Re)inits environment settings for this project intance.
#
# @see cwt/env/README.md
#
# Usage examples :
# $ . cwt/stack/init.sh                 # Will prompt to confirm/edit every default value
# $ . cwt/stack/init.sh -s drupal-7     # Short name/value argument syntax
# $ . cwt/stack/init.sh -s nodejs -y    # "-y" will use default values, no prompts
#

# Get named script arguments.
. cwt/stack/init/get_args.sh

# These globals are needed throughout this task's related scripts.
export GLOBALS
export GLOBALS_COUNT
export GLOBALS_UNIQUE_NAMES
export GLOBALS_UNIQUE_KEYS

export PROJECT_STACK="$P_PROJECT_STACK"
export PROVISION_USING="$P_PROVISION_USING"
export CWT_CUSTOM_DIR="$P_CWT_CUSTOM_DIR"
export GLOBALS_FILEPATH='cwt/env/current/global.vars.sh'

if [[ (-z "$PROJECT_STACK") && ($P_YES == 0) ]]; then
  read -p "Enter PROJECT_STACK value : " PROJECT_STACK
fi

if [[ -z "$PROJECT_STACK" ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO: cannot carry on without a value for \$PROJECT_STACK." >&2
  echo "Aborting (1)." >&2
  return 1
fi

# Remove previously generated globals to avoid any interference.
if [[ -f "$GLOBALS_FILEPATH" ]]; then
  rm "$GLOBALS_FILEPATH"
fi

# Load CWT includes.
. cwt/bootstrap.sh

# (Re)start dependencies and env vars aggregation.
unset GLOBALS
declare -A GLOBALS
GLOBALS_COUNT=0
GLOBALS_UNIQUE_NAMES=()
GLOBALS_UNIQUE_KEYS=()

# Get CWT globals required for aggregating dependencies and env vars.
. cwt/env/global.vars.sh

# Aggregate dependencies and env vars.
. cwt/stack/init/aggregate_deps.sh
. cwt/stack/init/aggregate_env_vars.sh

# Write env vars in current instance's git-ignored settings file.
. cwt/env/write.sh

# Apply correct ownership and permissions.
u_hook_app 'apply' 'ownership_and_perms' '' 'stack'

# Allow custom complements for this script.
# TODO evaluate removal of the 'complement' customization method.
u_autoload_get_complement "$BASH_SOURCE"

# Trigger stack/post-init hook.
u_hook 'stack' 'init' 'post'
