#!/usr/bin/env bash

##
# CWT core program-related tests.
#
# This group of tests ensures current host has all the programs (and versions)
# required to execute CWT core actions.
#
# @requires cwt/vendor/shunit2
#
# This file may be dynamically executed.
# @see cwt/test/self_test.sh
#
# @example
#   cwt/test/cwt/required_programs.test.sh
#

. cwt/bootstrap.sh

##
# Can we use all required commands from this instance ?
#
test_cwt_required_programs() {
  local p
  local programs_to_check='git tar'

  for p in $programs_to_check; do
    u_test_program_is_executable "$p"
    assertTrue \
      "The program or alias '$p' appears to be missing (or is not executable) on current host or instance." \
      "[ $? -eq 0 ]"
  done
}

# Load and run shUnit2.
. cwt/vendor/shunit2/shunit2
