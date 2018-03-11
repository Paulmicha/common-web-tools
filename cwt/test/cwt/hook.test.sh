#!/usr/bin/env bash

##
# CWT core hook-related tests.
#
# @requires cwt/vendor/shunit2
#
# This file may be dynamically executed.
# @see cwt/test/cwt.sh
#
# @example
#   cwt/test/cwt/hook.test.sh
#

. cwt/bootstrap.sh

##
# Single arg hook : action.
#
# Must trigger lookups
#
test_cwt_hook_single_action() {
  local inc_dry_run_files_list=''
  hook -a 'bootstrap' -t -d
  echo "inc_dry_run_files_list = $inc_dry_run_files_list"
  # assertFalse 'Global CWT_INC is empty (bootstrap test failed)' "[ -e $CWT_INC ]"
}

# Load and run shUnit2.
. cwt/vendor/shunit2/shunit2
