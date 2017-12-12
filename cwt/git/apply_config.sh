#!/usr/bin/env bash

##
# Git local config setup.
#
# @see env/.git.env.dist
#
# Usage from project root dir :
# $ . cwt/git/apply_config.sh
#

# Allow custom override for this script.
eval `u_autoload_override "$BASH_SOURCE"`

u_git_apply_config "$APP_GIT_WORK_TREE"

# Allow custom complements for this script.
u_autoload_get_complement "$BASH_SOURCE"
