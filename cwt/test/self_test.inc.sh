#!/usr/bin/env bash

##
# CWT test self_test action utility functions.
#
# This file is sourced during test self_test action execution (NOT bootstrap).
# @see cwt/test/self_test.sh
#
# Convention : functions names are all prefixed by "u" (for "utility").
#

##
# Custom hook test assertion helper.
#
# @param 1 String : failed test error message.
# @param 2 Int : numerical flag (error number).
#
# TODO [wip] @example
#
u_test_lookup_paths_assertion() {
  local p_msg="$1"
  local p_flag=$2

  local fail_reason
  case $flag in
    1) fail_reason='missing matching lookup paths' ;;
    2) fail_reason='too many matching lookup paths found' ;;
    *) fail_reason='unexpected error' ;;
  esac

  assertTrue "$p_msg (error $flag : $fail_reason)" "[ $flag -eq 0 ]"
}

##
# Custom hook expected result comparator helper.
#
# Writes result in the following variable in calling scope :
# @var flag
#
# @requires the following vars in calling scope :
# - hook_dry_run_matches
# - expected_list
#
# TODO [wip] implement proper params (instead of requiring
#   $hook_dry_run_matches + $expected_list vars in calling scope).
# TODO [wip] @example
#
u_test_compare_expected_lookup_paths() {
  local i
  local j
  local is_found

  local expected_count=0
  for i in $expected_list; do
    ((++expected_count))
  done

  local count_found=0
  for j in $hook_dry_run_matches; do
    ((++count_found))
  done

  flag=0

  for i in $expected_list; do
    is_found=0

    for j in $hook_dry_run_matches; do
      if [[ "$i" == "$j" ]]; then
        is_found=1
        break
      fi
    done

    if [[ $is_found -eq 0 ]]; then
      flag=1
      break
    fi
  done

  if [[ $flag -eq 0 ]] && [[ $count_found -ne $expected_count ]]; then
    flag=2
  fi
}
