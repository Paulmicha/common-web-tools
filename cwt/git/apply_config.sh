#!/bin/bash

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


# Require git user config. Prompt if not set globally, in which case we only
# apply git config to this instance.
GIT_USER_MAIL="$(git config user.email)"
if [[ -z "$GIT_USER_MAIL"]]; then
  git config user.email $(u_prompt "please enter your Git user EMAIL : ")
fi

GIT_USER_NAME="$(git config user.name)"
if [[ -z "$GIT_USER_NAME"]]; then
  git config user.name $(u_prompt "please enter your Git user NAME : ")
fi

# Always enforce the following settings.
git config push.default simple


# Allow custom complements for this script.
u_autoload_get_complement "$BASH_SOURCE"
