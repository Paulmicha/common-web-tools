#!/bin/bash

##
# CWT internals related utility functions.
#
# This file is dynamically loaded.
# @see cwt/bash_utils.sh
#

##
# Centralizes arbitrary unique values (e.g. for delimiters, placeholders, etc).
#
# @example
#   unique_delimiter_str="$(u_cwt_common_val globals-key-prefix)"
#   echo "$unique_delimiter_str"
#
u_cwt_common_val() {
  case "$1" in
    globals-key-prefix) echo ":cwt-gkp:" ;;
    globals-tmp-space-placeholder) echo ":cwt-tsph:" ;;
  esac
}

##
# [debug] Triggers CWT_ACTIONS by CWT_SUBJECTS + CWT_VARIANTS.
#
# TODO fragment hooks in a predictable manner (function name convention) ?
# e.g. ${CWT_SUBJECTS}[_${CWT_VARIANTS}]_${CWT_ACTIONS}() { ... }
#
# @requires the following globals in calling scope (main shell) :
# - $CWT_SUBJECTS
# - $CWT_ACTIONS
# - $CWT_VARIANTS
#
# @example
#   u_cwt_trigger
#
u_cwt_trigger() {
  local subject
  local action
  local hook_type

  for subject in $CWT_SUBJECTS; do
    for action in $CWT_ACTIONS; do
      u_hook "$subject" "$action"
      for hook_type in $CWT_VARIANTS; do
        u_hook "$subject" "$action" "$hook_type"
      done
    done
  done
}

##
# [wip] TODO wrap action calls by subject for "free" extensibility ?
#
# Idea: wrap all calls to ${CWT_SUBJECTS}[_${CWT_VARIANTS}]_${CWT_ACTIONS} to
# avoid having to manually implement u_autoload_complement() or
# u_autoload_override() or u_hook() + u_hook_${CWT_SUBJECTS} every time we need
# those includes.
#
# This could theoretically allow isolated "contexts" (bunch of includes
# loosely bundled in a single dir) by temporarily prefixing current (main)
# shell's relative file path.
# + simple lists ("piles" of CWT_SUBJECTS) -> implement offset or index ?
#
# u_cwt_preset_wrapper() {
# }
