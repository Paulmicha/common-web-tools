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
# @see cwt/extensions/docker-compose/test/self_test.hook.sh
#
# @example
#   cwt/extensions/docker-compose/test/dc/required_programs.test.sh
#

. cwt/bootstrap.sh

##
# Can we use all required commands from this instance ?
#
test_dc_extension_required_programs() {
  local p
  local programs_to_check='docker docker-compose'

  for p in $programs_to_check; do
    u_test_program_is_executable "$p"
    assertTrue \
      "The program or alias '$p' appears to be missing (or is not executable) on current host or instance." \
      "[ $? -eq 0 ]"
  done
}

# Load and run shUnit2.
. cwt/vendor/shunit2/shunit2
