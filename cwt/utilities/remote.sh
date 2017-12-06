#!/bin/bash

##
# Remote host-related utility functions.
#
# This file is dynamically loaded.
# @see cwt/bash_utils.sh
#

##
# TODO [wip] Executes scripts remotely.
#
# Status : trying to sync dev stack to remote in order to operate from local.
# (unfinished)
#
# See https://unix.stackexchange.com/a/326672
# (using the bash or ksh as /bin/sh version)
#
# @prereq u_remote_ssh_init()
#
# @param 1 String : ssh args.
# @param 2 String : script to execute.
# @param ... The rest will be forwarded to the script.
#
# @requires the following vars in calling scope (main shell) :
# - $REMOTE_INSTANCES
# - $REMOTE_INSTANCES_CMDS
# - $REMOTE_INSTANCES_TYPES
#
# @example
#   u_remote_cmd_wrapper
#
u_remote_cmd_wrapper() {
  local p_ssh
  local p_script
  local args

  p_ssh=$1; shift
  p_script=$1; shift

  if [[ -n "$@" ]]; then
    # generate eval-safe quoted version of current argument list
    printf -v args '%q ' "$@"

    # pass that through on the command line to bash -s
    # note that $args is parsed remotely by /bin/sh, not by bash!
    # ssh user@remote-addr "bash -s -- $args" < "$p_script"
    eval "ssh $p_ssh \"bash -s -- $args\" < \"$p_script\""
  else
    eval "ssh $p_ssh \"bash -s\" < \"$p_script\""
  fi
}
