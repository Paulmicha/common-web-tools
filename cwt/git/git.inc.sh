#!/usr/bin/env bash

##
# Git-related utility functions.
#
# TODO implement optional git hooks setup.
# Ex : cwt/git/hooks/pre_commit.sh
#
# This file is dynamically loaded.
# @see cwt/bootstrap.sh
#
# Convention : functions names are all prefixed by "u" (for "utility").
#

##
# List staged files only.
#
# @param 1 [optional] String : the git "working dir". Defaults to current dir.
# @param 2 [optional] String : the git dir. Defaults to "$1/.git".
#
# @example
#   # List staged files in current path.
#   staged="$(u_git_get_staged_files)"
#   for f in $staged; do
#     echo "staged file : $f"
#   done
#
#   # List staged files in given path.
#   staged="$(u_git_get_staged_files path/to/work/tree)"
#   for f in $staged; do
#     echo "staged file : $f"
#   done
#
u_git_get_staged_files() {
  local p_git_work_tree="$1"
  local p_git_dir=''

  if [[ -z "$p_git_work_tree" ]]; then
    p_git_work_tree='.'
  fi

  if [[ -n "$2" ]]; then
    p_git_dir="$2"
  else
    p_git_dir="$p_git_work_tree/.git"
  fi

  echo "$(u_git_wrapper diff --name-only --cached)"
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
# @example
#   u_git_wrapper status
#
#   # Execute the same command in another dir.
#   p_git_work_tree=path/to/git-work-tree
#   u_git_wrapper status
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
