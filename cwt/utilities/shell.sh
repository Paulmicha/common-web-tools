#!/usr/bin/env bash

##
# Bash shell utilities.
#
# This file is sourced during core CWT bootstrap.
# @see cwt/bootstrap.sh
#
# Convention : functions names are all prefixed by "u" (for "utility").
#

##
# Checks if current user is root (super user).
#
# See https://askubuntu.com/a/836092
#
# @example
#   if i_am_su; then
#     echo "I am root"
#   else
#     echo "I am not root"
#   fi
#
i_am_su() {
  ! ((${EUID:-0} || "$(id -u)"))
}
