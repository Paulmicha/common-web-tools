#!/usr/bin/env bash

##
# Convenience "instance init" wrapper for default 'make' task.
#
# It is necessary to convert arguments syntax when (ab)using make the way we do.
# This "entry point" script implements a custom named arguments conversion
# syntax to "forward" them as needed - i.e. replaces '-a' by 'a:'.
#
# @see cwt/instance/init.sh
# @see Makefile
# @see cwt/instance/hook.make.sh
#
# @example
#   cwt/instance/init.make.sh \
#     t:dev \
#     h:local \
#     p:ansible \
#     d:dev.cwt.com \
#     g:git@my-git-origin.org:my-git-account/cwt.git \
#     a:dist/web \
#     s:dist \
#     y:
#

formatted_args=" $@"

# Transform this script's arguments to the named arguments format expected by
# u_instance_init().
args_to_convert='o a g s t d h p c y r'
for a2c in $args_to_convert; do
  formatted_args="${formatted_args//" ${a2c}:"/" -${a2c} "}"
done

eval ". cwt/instance/init.sh $formatted_args"
