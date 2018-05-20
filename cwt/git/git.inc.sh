#!/usr/bin/env bash

##
# Git-related utility functions.
#
# This file is sourced during core CWT bootstrap.
# @see cwt/bootstrap.sh
#
# Convention : functions names are all prefixed by "u" (for "utility").
#

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
#     This hook is invoked by git merge, which happens when a git pull is done
#     on a local repository. It takes a single parameter, a status flag
#     specifying whether or not the merge being done was a squash merge.
#   - 'pre-push' : can be used to prevent a push from taking place (exit with a
#     non-zero status). The hook is called with two parameters which provide the
#     name and location of the destination remote, if a named remote is not
#     being used both values will be the same.
#   - 'post-receive' : executes on the remote repository once after all the refs
#     have been updated. This hook does not affect the outcome of
#     git-receive-pack, as it is called after the real work is done.
# @param 2 [optional] String : the Git hooks folder to use. Defaults to
#   "$APP_GIT_WORK_TREE/.git/hooks" if it exists, otherwise to
#   "$PROJECT_DOCROOT/.git/hooks".
#
# @example
#   u_git_write_hooks
#   u_git_write_hooks 'pre-commit post-merge'
#   u_git_write_hooks '' /my/custom/path/to/.git/hooks
#
u_git_write_hooks() {
  local p_git_hooks="$1"
  local p_git_hook_dir="$2"

  if [[ -z "$p_git_hooks" ]]; then
    p_git_hooks='pre-applypatch pre-commit post-checkout post-merge pre-push post-receive'
  fi

  if [[ -z "$p_git_hook_dir" ]]; then
    p_git_hook_dir="$PROJECT_DOCROOT/.git/hooks"

    if [[ -n "$APP_GIT_WORK_TREE" ]]; then
      p_git_hook_dir="$APP_GIT_WORK_TREE/.git/hooks"
    fi

    if [[ ! -d "$p_git_hook_dir" ]]; then
      echo >&2
      echo "Error in u_git_write_hooks() - $BASH_SOURCE line $LINENO: the Git hook dir '$p_git_hook_dir' is missing." >&2
      echo "-> Aborting (1)." >&2
      echo >&2
      exit 1
    fi
  fi

  # Whitelist allowed values for git hooks.
  local git_hook=''
  local git_hook_script_path=''
  local git_hooks_whitelist=()
  git_hooks_whitelist+=('applypatch-msg')
  git_hooks_whitelist+=('pre-applypatch')
  git_hooks_whitelist+=('post-applypatch')
  git_hooks_whitelist+=('pre-commit')
  git_hooks_whitelist+=('prepare-commit-msg')
  git_hooks_whitelist+=('commit-msg')
  git_hooks_whitelist+=('post-commit')
  git_hooks_whitelist+=('pre-rebase')
  git_hooks_whitelist+=('post-checkout')
  git_hooks_whitelist+=('post-merge')
  git_hooks_whitelist+=('pre-push')
  git_hooks_whitelist+=('pre-receive')
  git_hooks_whitelist+=('update')
  git_hooks_whitelist+=('post-update')
  git_hooks_whitelist+=('post-receive')
  git_hooks_whitelist+=('post-update')
  git_hooks_whitelist+=('push-to-checkout')
  git_hooks_whitelist+=('pre-auto-gc')
  git_hooks_whitelist+=('post-rewrite')
  git_hooks_whitelist+=('rebase')
  git_hooks_whitelist+=('sendemail-validate')
  git_hooks_whitelist+=('fsmonitor-watchman')

  for git_hook in $p_git_hooks; do

    # Whitelist allowed values for git hooks.
    if u_in_array "$git_hook" 'git_hooks_whitelist'; then
      git_hook_script_path="$p_git_hook_dir/$git_hook"

      # When Git triggers its hook, the path in which the script runs is either
      # APP_GIT_WORK_TREE or PROJECT_DOCROOT.
      # -> Since CWT requires to be run from PROJECT_DOCROOT, we need to force the
      # execution path from within the generated scripts.
      echo "(over)Writing git hook $git_hook_script_path ..."
      cat > "$git_hook_script_path" <<EOF
#!/usr/bin/env bash

##
# Implements '$git_hook' git hook.
#
# This file is automatically generated during "instance init", and it will be
# entirely overwritten every time it is executed.
#
# @see u_git_write_hooks() in cwt/git/git.inc.sh
# @see u_instance_init() in cwt/instance/instance.inc.sh
#

cd $PROJECT_DOCROOT && \
  . cwt/bootstrap.sh && \
  hook -s 'git' -a "$git_hook" -v 'PROVISION_USING HOST_TYPE INSTANCE_TYPE'

EOF
      chmod +x "$git_hook_script_path"
      echo "(over)Writing git hook $git_hook_script_path : done."

    else
      echo >&2
      echo "Error in u_git_write_hooks() - $BASH_SOURCE line $LINENO: the value '$git_hook' is invalid." >&2
      echo "-> Aborting (2)." >&2
      echo >&2
      exit 2
    fi
  done
}

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

  if [[ -z "$work_tree" ]] && [[ -n "$APP_GIT_WORK_TREE" ]]; then
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
