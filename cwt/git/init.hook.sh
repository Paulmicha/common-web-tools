#!/usr/bin/env bash

##
# Implements hook -a 'init'.
#
# By default, CWT core uses "instance init" to setup 2 things :
# - the application source files (clones repo if separate & not done already);
# - a default selection of Git hooks (overwritten by CWT hooks).
#
# @see u_git_write_hooks() in cwt/git/git.inc.sh
#

# Automatically clones the app repo if it is separate from the "dev stack" repo.
# Only attempts to clone if it's not already done (idempotent).
if [[ -n "$APP_GIT_ORIGIN" ]] \
  && [[ -n "$APP_GIT_WORK_TREE" ]] \
  && [[ ! -d "$APP_GIT_WORK_TREE/.git" ]]
then

  git clone "$APP_GIT_ORIGIN" "$APP_GIT_WORK_TREE"

  if [[ $? -ne 0 ]]; then
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO: the 'git clone' command failed (exited with non-zero code)." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    exit 1
  fi
fi

# (over)Writes Git hooks to use CWT hooks.
u_git_write_hooks
