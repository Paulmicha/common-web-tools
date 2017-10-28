#!/bin/bash

. cwt/bash_utils.sh

new='master'

# Do not proceed if branch is not the one we're tracking.
if [[ "${new}" != "master" ]]; then
  echo
  echo "Error in $BASH_SOURCE line $LINENO:"
  echo "Branch ${branch} is not master. Skipped!"
  echo "Deployment aborted."
  echo
fi

echo "Over."

# YES=0
# REG_BACKEND="file"
# PROVISION="scripts"
# PROJECT_STACK=""
# INSTANCE_TYPE="dev"

# # See https://stackoverflow.com/a/31443098
# while [ "$#" -gt 0 ]; do
#   case "$1" in
#     -r) REG_BACKEND="$2"; shift 2;;
#     -p) PROVISION="$2"; shift 2;;
#     -s) PROJECT_STACK="$2"; shift 2;;
#     -t) INSTANCE_TYPE="$2"; shift 2;;
#     -y) YES=1; shift 1;;

#     --reg=*) REG_BACKEND="${1#*=}"; shift 1;;
#     --provision=*) PROVISION="${1#*=}"; shift 1;;
#     --stack=*) PROJECT_STACK="${1#*=}"; shift 1;;
#     --type=*) INSTANCE_TYPE="${1#*=}"; shift 1;;
#     --yes) shift 1;;
#     --reg|--provision|--stack|--type) echo "Error in $BASH_SOURCE line $LINENO: $1 requires an argument" >&2; return;;

#     -*) echo "Error in $BASH_SOURCE line $LINENO: unknown option: $1" >&2; return;;
#     *) echo "Error in $BASH_SOURCE line $LINENO: unsupported unnamed argument: $1"; shift 1;;
#   esac
# done


# See https://stackoverflow.com/a/33826763
# while [[ "$#" > 1 ]]; do
#   case $1 in
#     -r|--reg) REG_BACKEND="$2";;
#     -p|--provision) PROVISION="$2";;
#     -s|--stack) PROJECT_STACK="$2";;
#     -t|--type) INSTANCE_TYPE="$2";;
#     *) break;;
#   esac; shift; shift
# done


# Get fancy script arguments.
# See https://stackoverflow.com/a/29754866
# getopt --test > /dev/null
# if [[ $? -ne 4 ]]; then
#   >&2 echo "Error in $BASH_SOURCE line $LINENO : this script requires enhanced getopt support."
#   return
# fi

# OPTIONS=rpst
# LONGOPTIONS=reg,provision,stack,type
# PARSED=$(getopt --options=$OPTIONS --longoptions=$LONGOPTIONS)

# if [[ $? -ne 0 ]]; then
#   >&2 echo "Error in $BASH_SOURCE line $LINENO : invalid arguments detected."
#   return
# fi

# eval set -- "$PARSED"

# while true; do
#   case "$1" in
#     -r|--reg)
#       REG_BACKEND=y
#       shift
#       ;;
#     -p|--provision)
#       PROVISION=y
#       shift
#       ;;
#     -s|--stack)
#       PROJECT_STACK=y
#       shift
#       ;;
#     -t|--type)
#       INSTANCE_TYPE=y
#       shift
#       ;;
#     *)
#       # >&2 echo "Error in $BASH_SOURCE line $LINENO : invalid argument detected."
#       # return
#       ;;
#   esac
# done

# echo "YES: $YES"
# echo "REG_BACKEND: $REG_BACKEND"
# echo "PROVISION: $PROVISION"
# echo "PROJECT_STACK: $PROJECT_STACK"
# echo "INSTANCE_TYPE: $INSTANCE_TYPE"
