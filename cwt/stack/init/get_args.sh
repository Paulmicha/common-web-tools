#!/bin/bash

##
# Options handling for stack init.
#
# See https://stackoverflow.com/a/31443098
# TODO use https://github.com/matejak/argbash instead.
#
# Naming convention : vars containing values passed as arguments are prefixed
# with "P_" and must have the same name as the expected global.
# Ex: P_PROJECT_STACK (param) -> PROJECT_STACK (global)
#
# TODO limit number of default variables, but provide extensibility (through
# convention ?) / make this as predictable as possible (variable names as "DSL" ?)
#
# @see cwt/stack/init.sh
#

# Mandatory param (no default fallback provided).
export P_PROJECT_STACK

# Default values :
# @see cwt/env/vars.sh
export P_PROJECT_DOCROOT
export P_APP_DOCROOT
export P_APP_GIT_ORIGIN
export P_APP_GIT_DIR
export P_INSTANCE_TYPE
export P_INSTANCE_DOMAIN

# Configurable CWT internals.
export P_HOST_TYPE
export P_PROVISION_USING
export P_DEPLOY_USING
export P_YES
export P_VERBOSE

# Make sure any previously set globals cannot interfere by resetting them.
unset P_PROJECT_STACK
unset P_PROJECT_DOCROOT
unset P_APP_DOCROOT
unset P_APP_GIT_ORIGIN
unset P_APP_GIT_DIR
unset P_INSTANCE_TYPE
unset P_INSTANCE_DOMAIN
unset P_HOST_TYPE
unset P_PROVISION_USING
unset P_DEPLOY_USING
P_YES=0
P_VERBOSE=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    -s) P_PROJECT_STACK="$2"; shift 2;;

    -o) P_PROJECT_DOCROOT="$2"; shift 2;;
    -a) P_APP_DOCROOT="$2"; shift 2;;
    -g) P_APP_GIT_ORIGIN="$2"; shift 2;;
    -i) P_APP_GIT_DIR="$2"; shift 2;;
    -t) P_INSTANCE_TYPE="$2"; shift 2;;
    -d) P_INSTANCE_DOMAIN="$2"; shift 2;;

    -h) P_HOST_TYPE="$2"; shift 2;;
    -p) P_PROVISION_USING="$2"; shift 2;;
    -e) P_DEPLOY_USING="$2"; shift 2;;
    -y) P_YES=1; shift 1;;
    -v) P_VERBOSE=1; shift 1;;

    -*) echo "Error in $BASH_SOURCE line $LINENO: unknown option: $1" >&2; return;;
    *) echo "Notice in $BASH_SOURCE line $LINENO: unsupported unnamed argument: $1" >&2; shift 1;;
  esac
done
