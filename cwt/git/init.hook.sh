#!/usr/bin/env bash

##
# Implements hook -a 'init'.
#
# Automatically clones the app repo if it is separate from the "dev stack" repo.
# Only attempts to clone if it's not already done (idempotent).
#
# @requires the following variables in calling scope (main shell) :
# - APP_GIT_ORIGIN
# - APP_GIT_WORK_TREE
#

if [[ "$CWT_MODE" == 'separate' ]] \
  && [[ -n "$APP_GIT_ORIGIN" ]] \
  && [[ -n "$APP_GIT_WORK_TREE" ]] \
  && [[ ! -d "$APP_GIT_WORK_TREE/.git" ]]
then
  git clone "$APP_GIT_ORIGIN" "$APP_GIT_WORK_TREE"
fi
