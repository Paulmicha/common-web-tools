#!/bin/bash

##
# Git hooks setup.
#
# [wip]
#
# Usage from project root dir :
# $ . cwt/git/hooks_setup.sh
#

ln -s cwt/git/hooks/pre_commit.sh .git/hooks/pre-commit
