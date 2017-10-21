#!/bin/bash

##
# Git local config setup.
#
# @see env/.git.env.dist
#
# Usage from project root dir :
# $ . cwt/git/apply_config.sh
#

git config user.email $GIT_USER_MAIL
git config user.name $GIT_USER_NAME
git config color.ui auto
git config push.default simple
