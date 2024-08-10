#!/usr/bin/env bash

##
# Make entry points arguments safety check.
#
# Make sure none of the "arguments" passed in make calls would trigger unwanted
# targets (since we use it as a kind of aliases list).
#
# @see u_instance_init() in cwt/instance/instance.inc.sh
# @see u_make_generate() in cwt/make/make.inc.sh
#
# @example
#   # All args passed to this script are checked.
#   cwt/make/check_args.sh arg1 arg2 ...
#

. cwt/bootstrap.sh

if [[ -z "$1" ]]; then
  echo
  echo "Need at least 1 non-empty argument to check."
  echo
  exit 0
fi

mk_tasks=()
mk_entry_points=()

u_make_list_entry_points

if [[ -z "${mk_tasks[@]}" ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO: make entry points not found." >&2
  echo "It seems local instance hasn't been initialized yet." >&2
  echo "@see cwt/instance/init.sh" >&2
  echo "-> Aborting (1)." >&2
  echo >&2
  exit 1
fi

entry=''

while [[ $# -gt 0 ]]; do
  for entry in "${mk_tasks[@]}"; do
    case "$1" in "$entry")
      echo >&2
      echo "The value '$1' is reserved as a Make entry point." >&2
      echo "-> Aborting (2)." >&2
      echo >&2
      exit 2
    esac
  done

  shift
done

echo "Ok, in this list :"
echo "  $@"
echo "all values are safe to use as arguments in any CWT make entry points."
echo
