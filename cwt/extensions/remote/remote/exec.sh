#!/usr/bin/env bash

##
# CWT remote exec action.
#
# A special hook is called BEFORE attempting to execute given command remotely
# in order to give other extensions a chance to react (e.g. to whitelist or
# blacklist some actions per instance).
#
# make hook-debug s:remote a:exec
#
# Implementations of this (optional) hook MUST use the following variables :
# - String $remote_id : remote instance's id (short name).
# - String $cmd : command or file path of a script to execute remotely - which
#     is relative to the PROJECT_DOCROOT of that remote instance.
# - String $args : sanitized arguments of the command.
#
# @example
#   # Warning : experimental shortcuts (ab)using 'make'.
#   # If used, commands with arguments MUST be quoted.
#   make remote-exec my_short_id 'cat .env'
#   make remote-exec my_short_id 'git status'
#   make remote-exec my_short_id 'git reset --hard'
#   make remote-exec my_short_id cwt/test/cwt/global.test.sh
#   # Or :
#   cwt/extensions/remote/remote/exec.sh my_short_id cat .env
#   cwt/extensions/remote/remote/exec.sh my_short_id git status
#   cwt/extensions/remote/remote/exec.sh my_short_id git reset --hard
#   cwt/extensions/remote/remote/exec.sh my_short_id cwt/test/cwt/global.test.sh
#

. cwt/bootstrap.sh

raw_args=$@
remote_id="$1"

u_remote_check_id "$remote_id"

cmd="$2"
args=''

shift 2

# Sanitize the arguments of this script for hook call below (the variable 'args'
# will contain the sanitized input, which is what hook implementations will use).
if [[ -n "$@" ]]; then
  printf -v args '%q ' "$@"
fi

hook -s 'remote' -a 'exec'

u_remote_exec_wrapper $raw_args
