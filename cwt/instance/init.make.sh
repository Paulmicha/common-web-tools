#!/usr/bin/env bash

##
# Convenience "instance init" wrapper for default 'make' task.
#
# @see cwt/instance/init.sh
#
# It uses a custom named arguments conversion syntax to "forward" them as needed.
#
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
#     i:dist \
#     a:dist/web \
#     y:
#

formatted_args=" $@"

# Transform this script's arguments to the named arguments format expected by
# u_instance_init().
args_to_convert='o a g i t d h p c y r'
for a2c in $args_to_convert; do
  formatted_args="${formatted_args//" ${a2c}:"/" -${a2c} "}"
done

eval ". cwt/instance/init.sh $formatted_args"
