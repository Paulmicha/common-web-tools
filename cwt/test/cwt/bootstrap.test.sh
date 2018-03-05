#!/usr/bin/env bash

##
# CWT core bootstrap-related tests.
#
# @requires cwt/vendor/shunit2
#
# This file may be dynamically executed.
# @see cwt/test/cwt.sh
#
# @example
#   cwt/test/cwt/bootstrap.test.sh
#

. cwt/bootstrap.sh

##
# Are all required CWT core globals successfully initialized ?
#
# @see u_cwt_extend()
#
test_cwt_has_essential_globals() {
  assertFalse 'Global CWT_SUBJECTS is empty (bootstrap test failed)' "[ -e \"$CWT_SUBJECTS\" ]"
  assertFalse 'Global CWT_ACTIONS is empty (bootstrap test failed)' "[ -e \"$CWT_ACTIONS\" ]"
  assertFalse 'Global CWT_INC is empty (bootstrap test failed)' "[ -e \"$CWT_INC\" ]"
}

# Load and run shUnit2.
. cwt/vendor/shunit2/shunit2
