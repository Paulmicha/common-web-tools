#!/bin/bash

##
# Git hooks setup.
#
# [wip]
#
# Usage from project root dir :
# $ . scripts/git/hooks_setup.sh
#

ln -s scripts/git/hooks/pre_commit.sh .git/hooks/pre-commit
