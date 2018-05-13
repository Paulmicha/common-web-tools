#!/usr/bin/env bash

##
# Implements Git 'pre-commit' hook.
#
# @see cwt/git/hooks_setup.sh
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
