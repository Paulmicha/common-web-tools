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
test_cwt_hook_single_action() {
  local dry_run_hook=1
  hook -a 'install'
  assertFalse 'Global CWT_INC is empty (bootstrap test failed)' "[ -e \"$CWT_INC\" ]"
}

# Load and run shUnit2.
. cwt/vendor/shunit2/shunit2
