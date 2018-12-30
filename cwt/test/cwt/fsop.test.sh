#!/usr/bin/env bash

##
# CWT core file system permissions-related tests.
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
# Can CWT create directories in current dir ?
#
# @evol see cwt/vendor/shunit2/examples/mkdir_test.sh
#
test_cwt_can_create_dir() {
  mkdir '_cwt_dir_test'
  assertTrue 'Directory missing (creation test failed)' "[ -d '_cwt_dir_test' ]"
}

##
# Can CWT change permissions ?
#
test_cwt_can_chmod() {
  local rtrn
  chmod 700 '_cwt_dir_test'
  rtrn=$?
  assertEquals 'Chmod failed (returned non-zero code)' 0 $rtrn
}

##
# Can CWT create files in current dir ?
#
test_cwt_can_create_file() {
  touch '_cwt_dir_test/_cwt_file_test.txt'
  assertTrue 'File missing (creation test failed)' "[ -f '_cwt_dir_test/_cwt_file_test.txt' ]"
}

##
# Can CWT change ownership ?
# Update : removed (would require sudoing, not enforceable).
#
# test_cwt_can_chown() {
#   local rtrn
#   chown 81:81 '_cwt_dir_test/_cwt_file_test.txt'
#   rtrn=$?
#   assertEquals 'Chown failed (returned non-zero code)' 0 $rtrn
# }

##
# Cleans up any leftovers from previous tests.
#
# (Internal shunit2 function called after all tests have run.)
#
oneTimeTearDown() {
  rm -fr '_cwt_dir_test'
}

# Load and run shUnit2.
. cwt/vendor/shunit2/shunit2
