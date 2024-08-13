#!/usr/bin/env bash

##
# Make entry points arguments safety check.
#
# This ensures none of the "arguments" passed in make calls would trigger
# unwanted targets (since we use it as a kind of aliases list).
#
# The default hardcoded Make entry points can be called before the local
# instance is initialized and the generated cache file does not exist yet.
#
# @see cwt/make/default.mk
# @see scripts/cwt/local/generated.mk
# @see scripts/cwt/local/cache/make.sh
# @see u_instance_init() in cwt/instance/instance.inc.sh
# @see u_make_generate() in cwt/make/make.inc.sh
#
# @example
#   # Calling :
#   make debug arg1 "'arg2 with space'" arg3
#
#   # Will mean :
#   real_script = cwt/make/echo.make.sh
#   make_entry_point = debug
#   wrapped call :
#     eval "$real_script $escaped_args"
#     # Result (real call) :
#     cwt/make/echo.make.sh arg1 'arg2 with space' arg3
#
#   # Inside the target script (in this example it's cwt/make/echo.make.sh) :
#   args :
#     1 : arg1
#     2 : arg2 with space
#     3 : arg3
#
#   # Why enclosing quotes "'arg2 with space'" ? Because if you do that :
#   make debug arg1 'arg2 with space' arg3
#
#   # Then the script would receive :
#   args :
#     1 : arg1
#     2 : arg2
#     3 : with
#     4 : space
#     5 : arg3
#
#   # Inline php code execution example :
#   make drush ev $(cwt/escape.sh '$test = "Printed from Drupal php"; print $test;')
#

. cwt/bootstrap.sh

# Debug.
# echo
# echo "raw args :"
# echo "  $@"

p_real_script="$1"
shift

if [[ ! -f "$p_real_script" ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO : script '$p_real_script' not found." >&2
  echo "-> Aborting (1)." >&2
  echo >&2
  exit 1
fi

make_entry_point="$1"
shift

make_entries=()
real_scripts=()

# Use the complete generated list of entries if it exists.
if [[ -f scripts/cwt/local/cache/make.sh ]]; then
  . scripts/cwt/local/cache/make.sh
else
  # Default to hardcoded values.
  u_make_list_hardcoded
fi

# Debug.
# echo
# echo "p_real_script = $p_real_script"
# echo "make_entry_point = $make_entry_point"

# Won't use that here to do all in one loop below.
# u_make_check_args $@

rest_of_args="$@"

# Debug.
# args=()

escaped_args=''

while [ $# -gt 0 ]; do
  arg="$1"

  # Debug.
  # echo
  # echo "processing arg :"
  # echo "  $arg"

  # args+=("$arg")

  # First, make sure the rest of the args won't accidentally trigger another
  # entry point.
  for i in "${!make_entries[@]}"; do
    make_entry_point="${make_entries[i]}"
    real_script="${real_scripts[i]}"

    case "$arg" in "$make_entry_point")
      echo >&2
      echo "The value '$arg' is reserved as a Make entry point." >&2
      echo "Use the following equivalent command instead :" >&2
      echo >&2
      echo "  $p_real_script $rest_of_args" >&2
      echo >&2
      exit 2
    esac
  done

  # Revert the special characters swap to send correct script argument.
  # @see cwt/escape.sh
  # @see cwt/make/make.inc.sh
  u_make_unescape "$arg" 'arg'

  # Any value which must be quoted is rewritten with single quotes.
  u_str_escape_single_quotes "$arg"

  escaped_args+="$escaped_arg "

  shift
done

# Debug.
# echo
# echo "  array args :"
# echo "    ${!args[@]}"
# echo "    ${args[@]}"
# echo
# echo "escaped args :"
# echo "  $escaped_args"
# echo
# echo "call :"
# echo "  $p_real_script $escaped_args"
# echo

eval "$p_real_script $escaped_args"
