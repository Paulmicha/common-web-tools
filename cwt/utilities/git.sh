#!/bin/bash

##
# Git-related utility functions.
#
# This script is dynamically loaded.
# @see cwt/bash_utils.sh
#
# Convention : functions names are all prefixed by "u" (for "utility").
#

##
# Applies common Git config.
#
# @param 1 String : the git "working dir".
# @param 2 [optional] String : the git dir. Defaults to "$1/.git".
#
# @example
#   u_git_apply_config "$APP_GIT_DIR"
#
u_git_apply_config() {
  local work_tree="$1"
  local git_dir="$work_tree/.git"

  if [[ -n "$2" ]]; then
    git_dir="$2"
  fi

  # Require git user config. Prompt if not set globally, in which case we only
  # apply git config to this instance.
  GIT_USER_MAIL="$(git config user.email)"
  if [[ -z "$GIT_USER_MAIL" ]]; then
    git --git-dir="$git_dir" --work-tree="$work_tree" config user.email $(u_prompt "please enter your Git user EMAIL : ")
  fi

  GIT_USER_NAME="$(git config user.name)"
  if [[ -z "$GIT_USER_NAME" ]]; then
    git --git-dir="$git_dir" --work-tree="$work_tree" config user.name $(u_prompt "please enter your Git user NAME : ")
  fi

  # Always enforce the following settings.
  git --git-dir="$git_dir" --work-tree="$work_tree" config push.default simple
}
