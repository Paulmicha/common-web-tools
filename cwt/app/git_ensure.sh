#!/usr/bin/env bash

##
# Ensures app git work tree is on given branch and up to date.
#
# This performs a git checkout + git pull from default remote (e.g.'origin').
# Requires a clean work tree, or at least no error on checkout to given branch.
#
# @param 1 [optional] String : the Git branch.
#   Defaults to 'master'.
#
# @example
#   # Master branch :
#   make app-git-ensure
#   # Or :
#   cwt/app/git_ensure.sh
#
#   # Branch 'stage' :
#   make app-git-ensure 'stage'
#   # Or :
#   cwt/app/git_ensure.sh 'stage'
#

. cwt/bootstrap.sh

branch="$1"
if [[ -z "$branch" ]]; then
  branch='master'
fi

echo "Ensuring app git work tree is on branch '$branch' and up to date ..."

u_git_wrapper checkout "$branch"

if [[ $? -ne 0 ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO: failed to checkout branch '$branch'." >&2
  echo "-> Aborting (1)." >&2
  echo >&2
  exit 1
fi

u_git_wrapper pull

if [[ $? -ne 0 ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO: failed to pull branch '$branch'." >&2
  echo "-> Aborting (2)." >&2
  echo >&2
  exit 2
fi

echo "Ensuring app git work tree is on branch '$branch' and up to date : done."
echo
