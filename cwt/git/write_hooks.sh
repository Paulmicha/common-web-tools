#!/usr/bin/env bash

##
# (over)Writes Git hooks to use CWT hooks.
#
# Applies to folder "$APP_GIT_WORK_TREE/.git/hooks" if it exists, otherwise to
# "$PROJECT_DOCROOT/.git/hooks".
#
# CWT hook triggers will have the following format :
# $ hook -s 'git' -a "$git_hook" -v 'PROVISION_USING HOST_TYPE INSTANCE_TYPE'
#
# TODO [evol] Examine opt-in alternative to use a custom value for "git config
# core.hooksPath" (instead of just generating scripts in "$GIT_DIR/hooks").
#
# @see https://git-scm.com/docs/githooks
#
# @param 1 [optional] String : the space-separated Git hooks to (over)write.
#   Defaults to the following selection (when value is absent or empty) :
#   - 'pre-applypatch' : used to inspect the current working tree and refuse to
#     make a commit (exits with non-zero status) if it does not pass certain
#     test(s).
#   - 'pre-commit' (see post-merge) : used for permissions/ownership, ACLS, etc.
#     Prevents commit when exiting with a non-zero status. Can be bypassed with
#     the 'git commit --no-verify' option.
#   - 'post-checkout' : used to perform repository validity checks, auto-display
#     differences from the previous HEAD if different, or set working dir
#     metadata properties (e.g. permissions/ownership). The hook is given three
#     parameters: the ref of the previous HEAD, the ref of the new HEAD (which
#     may or may not have changed), and a flag indicating whether the checkout
#     was a branch checkout (changing branches, flag=1) or a file checkout
#     (retrieving a file from the index, flag=0).
#   - 'post-merge' (see pre-commit) : used for permissions/ownership, ACLS, etc.
#     The hook takes a single parameter, a status flag specifying whether or not
#     the merge being done was a squash merge.
#   - 'pre-push' : can be used to prevent a push from taking place (exit with a
#     non-zero status). The hook is called with two parameters which provide the
#     name and location of the destination remote, if a named remote is not
#     being used both values will be the same.
# @param 2 [optional] String : the Git hooks folder to use. Defaults to
#   "$APP_GIT_WORK_TREE/.git/hooks" if it exists, otherwise to
#   "$PROJECT_DOCROOT/.git/hooks".
#
# @example
#   cwt/git/write_hooks.sh
#   cwt/git/write_hooks.sh 'pre-commit post-merge'
#   cwt/git/write_hooks.sh '' /my/custom/path/to/.git/hooks
#

. cwt/bootstrap.sh
u_git_write_hooks "$@"
