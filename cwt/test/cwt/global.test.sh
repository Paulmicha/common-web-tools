#!/usr/bin/env bash

##
# CWT core global vars related tests.
#
# @requires cwt/vendor/shunit2
#
# This file may be dynamically executed.
# @see cwt/test/cwt.sh
#
# @example
#   cwt/test/cwt/fsop.test.sh
#

. cwt/bootstrap.sh

##
# TODO [wip] Does the initial agregation process work ?
#
test_cwt_global_aggregate() {
  # assertTrue 'Directory missing (creation test failed)' "[ -d '_cwt_dir_test' ]"
}

##
# Cleans up any leftovers from previous tests.
#
# (Internal shunit2 function called after all tests have run.)
#
# oneTimeTearDown() {
#   rm -fr '_cwt_dir_test'
# }

# Load and run shUnit2.
. cwt/vendor/shunit2/shunit2
