#!/bin/bash

##
# Options handling for stack init.
#
# See https://stackoverflow.com/a/31443098
# TODO use https://github.com/matejak/argbash instead ?
#
# Naming convention : vars containing values passed as arguments are prefixed
# with "P_".
#
# @see cwt/stack/init.sh
#

export P_YES
export P_VERBOSE
export P_PROJECT_STACK
export P_PROVISION_USING
export P_REG_BACKEND
export P_INSTANCE_TYPE
export P_INSTANCE_DOMAIN

# Make sure any previously set globals cannot interfere by resetting them.
P_YES=0
P_VERBOSE=0
unset P_PROJECT_STACK
unset P_PROVISION_USING
unset P_REG_BACKEND
unset P_INSTANCE_TYPE
unset P_INSTANCE_DOMAIN

while [ "$#" -gt 0 ]; do
  case "$1" in
    -r) P_REG_BACKEND="$2"; shift 2;;
    -p) P_PROVISION_USING="$2"; shift 2;;
    -s) P_PROJECT_STACK="$2"; shift 2;;
    -t) P_INSTANCE_TYPE="$2"; shift 2;;
    -d) P_INSTANCE_DOMAIN="$2"; shift 2;;
    -y) P_YES=1; shift 1;;
    -v) P_VERBOSE=1; shift 1;;

    --reg=*) P_REG_BACKEND="${1#*=}"; shift 1;;
    --provision=*) P_PROVISION_USING="${1#*=}"; shift 1;;
    --stack=*) P_PROJECT_STACK="${1#*=}"; shift 1;;
    --type=*) P_INSTANCE_TYPE="${1#*=}"; shift 1;;
    --domain=*) P_INSTANCE_DOMAIN="${1#*=}"; shift 1;;
    --yes) P_YES=1; shift 1;;
    --verbose) P_VERBOSE=1; shift 1;;
    --reg|--provision|--stack|--type) echo "Error in $BASH_SOURCE line $LINENO: $1 requires an argument" >&2; return;;

    -*) echo "Error in $BASH_SOURCE line $LINENO: unknown option: $1" >&2; return;;
    *) echo "Notice in $BASH_SOURCE line $LINENO: unsupported unnamed argument: $1" >&2; shift 1;;
  esac
done

# echo "P_YES: $P_YES"
# echo "P_VERBOSE: $P_VERBOSE"
# echo "P_REG_BACKEND: $P_REG_BACKEND"
# echo "P_PROVISION_USING: $P_PROVISION_USING"
# echo "P_PROJECT_STACK: $P_PROJECT_STACK"
# echo "P_INSTANCE_TYPE: $P_INSTANCE_TYPE"
# echo "P_INSTANCE_DOMAIN: $P_INSTANCE_DOMAIN"
