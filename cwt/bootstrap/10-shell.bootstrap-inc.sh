#!/usr/bin/env bash

##
# Bootstrap phase: enable alias expansion in non-interactive shells.
#
# Sourced only from cwt/bootstrap.sh (inside CWT_BS_FLAG).
#
# @see cwt/bootstrap.sh
#

# NB: aliases are not expanded when the shell is not interactive, unless the
# expand_aliases shell option is set using shopt.
# See https://unix.stackexchange.com/a/1498
shopt -s expand_aliases
