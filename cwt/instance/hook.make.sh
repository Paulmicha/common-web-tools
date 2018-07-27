#!/usr/bin/env bash

##
# CWT instance hook call wrapper for convenience 'make' task.
#
# It is necessary to convert arguments syntax when (ab)using make the way we do.
# This "entry point" script implements a custom named arguments conversion
# syntax to "forward" them as needed - i.e. replaces '-a' by 'a:'.
#
# E.g. if we want to execute hook -s 'instance' -a 'start', we would use :
# $ make hook s:instance a:start
#
# Important note : named argument values containing spaces must be entered
# without quotes. The quotes are automatically set by this script.
#
# @see Makefile
#
# @example
#   # Print lookup paths for the CWT hook call :
#   # hook -s 'instance' -a 'stop' -v 'PROVISION_USING HOST_TYPE'
#   cwt/instance/hook.make.sh -d -t s:instance a:stop v:PROVISION_USING HOST_TYPE
#
#   # Print result of the "most specific" hook call variant :
#   cwt/instance/hook.make.sh -d -t ms s:instance a:stop v:PROVISION_USING HOST_TYPE
#
#   # Trigger "instance start" manually :
#   cwt/instance/hook.make.sh s:instance a:start
#
#   # Print lookup paths for "instance start" using PROVISION_USING variant :
#   cwt/instance/hook.make.sh -d -t s:instance a:start v:PROVISION_USING
#   # Same but using more variants :
#   cwt/instance/hook.make.sh -d -t s:instance a:start v:PROVISION_USING HOST_TYPE INSTANCE_TYPE
#

. cwt/bootstrap.sh

debug_mode=0
hook_mode='normal'
formatted_args=''

while [[ $# -gt 0 ]]; do
  case "$1" in
    ms) hook_mode='most-specific' ; shift 1;;
    -d) debug_mode=1 ; formatted_args+=" $1" ; shift 1;;
    *) formatted_args+=" $1" ; shift 1;;
  esac
done

# Transform this script's arguments to the named arguments format expected by
# hook(). We're faking delimiters to fabricate correct opening and closing
# quotes for named argument values containing spaces (using '<' and '>').
args_to_convert='a s p v e c'
for a2c in $args_to_convert; do
  formatted_args="${formatted_args//"${a2c}:"/">< -${a2c} '"}"
done

formatted_args="<$formatted_args >"
formatted_args="${formatted_args//'< >'/}"
formatted_args="${formatted_args//'< -d -t >'/'-d -t '}"
formatted_args="${formatted_args//'<'/}"
formatted_args="${formatted_args//[[:space:]]>/\'}"

case "$hook_mode" in
  'most-specific')
    if [[ $debug_mode -eq 1 ]]; then
      formatted_args="${formatted_args//'-d -t'/}"
      eval "u_hook_most_specific dry-run $formatted_args"
      u_autoload_print_lookup_paths hook_most_specific_dry_run_match "u_hook_most_specific $formatted_args"
    else
      eval "u_hook_most_specific $formatted_args"
    fi
  ;;
  *)
    eval "hook $formatted_args"
  ;;
esac
