#!/usr/bin/env bash

##
# Searches log messages and list files changed in matching commits.
#
# @param 1 String : The (grep) search pattern.
# @param 2 [optional] String : A branch name to restrict the search.
#   Defaults to all branches.
#
# @example
#   # Search log messages in all branches and list all files changed in all
#   # matching commits :
#   cwt/git/find_changed_files.sh 'JRA-224'
#   # Or :
#   make git-find-changed-files 'JRA-224'
#
#   # Same, by only search in a specific branch only :
#   cwt/git/find_changed_files.sh 'JRA-224' 'my-branch-name'
#   # Or :
#   make git-find-changed-files 'JRA-224' 'my-branch-name'
#

. cwt/bootstrap.sh

u_git_find_changed_files $@

for f in "${git_changed_files[@]}"; do
  echo "$f"
done
