#!/usr/bin/env bash

##
# Sample implementation of hook -s 'git' -a 'pre-commit'.
#
# @see cwt/git/git.inc.sh
#
# This example is inactive. To be used for real when CWT hook is triggered,
# this file would have to be placed in 'git/pre-commit.hook.sh' in an extension.
# To list all the possible paths that can be used, use :
#
# $ make hook-debug s:git a:pre-commit
#

# Include globals, aliases, utility functions (CWT).
. cwt/bootstrap.sh

# (Re)set file system ownership and permissions.
hook -s 'app instance' -a 'set_fsop'

# Re-add previously staged files in case their permissions have changed.
staged="$(u_git_get_staged_files "$APP_GIT_WORK_TREE")"
for f in $staged; do
  u_git_wrapper add "$f"
done
