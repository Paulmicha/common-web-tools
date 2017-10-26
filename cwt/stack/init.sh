#!/bin/bash

##
# Init environment settings for this project intance.
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

# Get named script arguments.
# See https://stackoverflow.com/a/31443098
# Naming convention : vars containing values passed as arguments are prefixed
# with "P_".
P_YES=0
P_REG_BACKEND="file"
P_PROVISION="docker-compose"
P_PROJECT_STACK=""
P_INSTANCE_TYPE="dev"
P_INSTANCE_DOMAIN="dev"

while [ "$#" -gt 0 ]; do
  case "$1" in
    -r) P_REG_BACKEND="$2"; shift 2;;
    -p) P_PROVISION="$2"; shift 2;;
    -s) P_PROJECT_STACK="$2"; shift 2;;
    -t) P_INSTANCE_TYPE="$2"; shift 2;;
    -d) P_INSTANCE_DOMAIN="$2"; shift 2;;
    -y) P_YES=1; shift 1;;

    --reg=*) P_REG_BACKEND="${1#*=}"; shift 1;;
    --provision=*) P_PROVISION="${1#*=}"; shift 1;;
    --stack=*) P_PROJECT_STACK="${1#*=}"; shift 1;;
    --type=*) P_INSTANCE_TYPE="${1#*=}"; shift 1;;
    --domain=*) P_INSTANCE_DOMAIN="${1#*=}"; shift 1;;
    --yes) P_YES=1; shift 1;;
    --reg|--provision|--stack|--type) echo "Error in $BASH_SOURCE line $LINENO: $1 requires an argument" >&2; return;;

    -*) echo "Error in $BASH_SOURCE line $LINENO: unknown option: $1" >&2; return;;
    *) echo "Notice in $BASH_SOURCE line $LINENO: unsupported unnamed argument: $1" >&2; shift 1;;
  esac
done

# TODO generate conditional values.
echo "P_YES: $P_YES"
echo "P_REG_BACKEND: $P_REG_BACKEND"
echo "P_PROVISION: $P_PROVISION"
echo "P_PROJECT_STACK: $P_PROJECT_STACK"
echo "P_INSTANCE_TYPE: $P_INSTANCE_TYPE"
echo "P_INSTANCE_DOMAIN: $P_INSTANCE_DOMAIN"

# Write in current instance env settings file.
. cwt/env/write.sh
