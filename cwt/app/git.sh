#!/usr/bin/env bash

##
# Entry point / "bridge" to execute git commands in app dir from project docroot.
#
# Useful if the "dev stack" has its own separate Git repo.
#
# @requires APP_GIT_WORK_TREE global.
# @see cwt/env/global.vars.sh
# @see u_git_wrapper() in cwt/git/git.inc.sh
#
# @example
#   make app-git 'status'
#   make app-git 'pull'
#   make app-git 'gc'
#   make app-git 'checkout develop'
#   make app-git 'diff --name-only'
#   # Or :
#   cwt/app/git.sh status
#   cwt/app/git.sh pull
#   cwt/app/git.sh gc
#   cwt/app/git.sh checkout develop
#   cwt/app/git.sh diff --name-only
#

. cwt/bootstrap.sh

u_git_wrapper $@
