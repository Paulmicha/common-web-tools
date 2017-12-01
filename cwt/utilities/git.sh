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
# @param 1 [optional] String : the git "working dir". Defaults to global
#   APP_GIT_WORK_TREE if it exists in calling scope, or none.
# @param 2 [optional] String : the git dir. Defaults to "$1/.git".
#
# @example
#   u_git_apply_config
#
#   # Notice that NO TRAILING SLASH is used in arg (requirement).
#   u_git_apply_config /custom/path/to/another/git/work/tree
#
u_git_apply_config() {
  local p_git_work_tree="$1"
  local p_git_dir="$p_git_work_tree/.git"
  if [[ -n "$2" ]]; then
    p_git_dir="$2"
  fi

  # Require git user config. Prompt if not set globally, in which case we only
  # apply git config to this instance.
  GIT_USER_MAIL="$(git config user.email)"
  if [[ -z "$GIT_USER_MAIL" ]]; then
    u_git_wrapper config user.email $(u_prompt "please enter your Git user EMAIL : ")
  fi

  GIT_USER_NAME="$(git config user.name)"
  if [[ -z "$GIT_USER_NAME" ]]; then
    u_git_wrapper config user.name $(u_prompt "please enter your Git user NAME : ")
  fi

  # Always enforce the following settings.
  u_git_wrapper config push.default simple
}

##
# Wraps git calls to exec commands from PROJECT_DOCROOT for different repos.
#
# @uses the following [optional] vars in calling scope :
# - $p_git_work_tree - String : the git "working dir". Defaults to
#   APP_GIT_WORK_TREE if it exists in calling scope, or none.
# - $p_git_dir - String : the git dir. Defaults to none or
#   "$p_git_work_tree/.git".
#
u_git_wrapper() {
  local cmd=''
  local work_tree="$p_git_work_tree"

  if [[ (-z "$work_tree") && (-n "$APP_GIT_WORK_TREE") ]]; then
    work_tree="$APP_GIT_WORK_TREE"
  fi

  if [[ -n "$work_tree" ]]; then
    local git_dir="$work_tree/.git"

    if [[ -n "$p_git_dir" ]]; then
      git_dir="$p_git_dir"
    fi

    eval "git --git-dir=$git_dir --work-tree=$work_tree $@"

  else
    eval "git $@"
  fi
}
