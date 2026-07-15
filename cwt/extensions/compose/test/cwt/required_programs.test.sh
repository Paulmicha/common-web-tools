#!/usr/bin/env bash

##
# Docker-compose extension program-related tests.
#
# This group of tests ensures current host has all the programs (and versions)
# required to execute this extension's actions.
#
# @requires cwt/vendor/shunit2
#
# This file may be dynamically executed.
# @see cwt/extensions/compose/test/cwt.hook.sh
#
# @example
#   cwt/extensions/compose/test/cwt/required_programs.test.sh
#

. cwt/bootstrap.sh

##
# Can we use all required commands from this instance ?
#
test_dc_extension_required_programs() {
  u_test_program_is_executable 'docker'

  assertTrue \
    "The program or alias '$p' appears to be missing (or is not executable) on current host or instance." \
    "[ $? -eq 0 ]"
}

# Load and run shUnit2.
. cwt/vendor/shunit2/shunit2
