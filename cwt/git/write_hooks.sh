#!/usr/bin/env bash

##
# (over)Writes Git hooks to use CWT hooks.
#
# @example
#   cwt/git/write_hooks.sh
#

. cwt/bootstrap.sh
u_git_write_hooks "$@"
