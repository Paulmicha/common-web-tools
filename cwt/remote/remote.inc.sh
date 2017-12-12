#!/usr/bin/env bash

##
# Remote host-related utility functions.
#
# This file is dynamically loaded.
# @see cwt/bootstrap.sh
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

##
# Adds a remote instance to current instance's existing globals.
#
# @param 1 String : remote instance's host domain.
# @param 2 String : remote instance's type (dev, production, etc).
# @param 3 String : remote instance's host connection command.
# @param 4 String : remote instance's PROJECT_DOCROOT value.
# @param 5 [optional] String : remote instance's APP_DOCROOT value. Defaults to:
#   "$p_project_docroot/web"
# @param 6 [optional] Array : additional declarations in the form:
#   "[append]=$p_host_type [to]=$p_host_domain|type"
#
# @example
#   # Basic example with only mandatory params :
#   u_remote_instance_add \
#     'remote.instance.cwt.com' \
#     'dev' \
#     'ssh -p123 username@cwt.com' \
#     '/path/to/remote/instance/docroot'
#
u_remote_instance_add() {
  local p_host_domain="$1"
  local p_host_type="$2"
  local p_connect_cmd="$3"
  local p_project_docroot="$4"
  local p_app_docroot="$5"
  local p_extra_declarations=$6[@]

  if [[ -z "$p_app_docroot" ]]; then
    p_app_docroot="$p_project_docroot/web"
  fi

  declare -a declarations

  declarations+=("[append]=$p_host_domain [to]=domains")
  declarations+=("[append]=$p_host_type [to]=$p_host_domain|type")
  declarations+=("[append]='$p_connect_cmd' [to]=$p_host_domain|connect")
  declarations+=("[append]='$p_project_docroot' [to]=$p_host_domain|PROJECT_DOCROOT")
  declarations+=("[append]='$p_app_docroot' [to]=$p_host_domain|APP_DOCROOT")

  local declaration
  for declaration in ${!p_extra_declarations}; do
    declarations+=("$declaration")
  done

  u_global_update_var 'REMOTE_INSTANCES' declarations
}
