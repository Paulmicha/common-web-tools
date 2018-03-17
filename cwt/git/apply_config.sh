#!/usr/bin/env bash

##
# Git local config setup.
#
# @example
#   cwt/git/apply_config.sh
#

# TODO refacto by implementing another hook, e.g. post stack init.
u_git_apply_config "$APP_GIT_WORK_TREE"

# Allow custom complements for this script.
u_autoload_get_complement "$BASH_SOURCE"
