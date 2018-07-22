#!/usr/bin/env bash

##
# MySQL extension program-related tests.
#
# This group of tests ensures current host has all the programs (and versions)
# required to execute this extension's actions.
#
# Important note : for stacks provisionned by tools like docker-compose,
# these tests require prior initialization in order to include aliases.
#
# @requires cwt/vendor/shunit2
#
# This file may be dynamically executed.
# @see cwt/extensions/mysql/test/self_test.hook.sh
#
# @example
#   cwt/extensions/mysql/test/mysql/required_programs.test.sh
#

. cwt/bootstrap.sh

##
# Can we use all required commands from this instance ?
#
test_mysql_extension_required_programs() {
  local p
  local programs_to_check='mysql mysqldump'

  for p in $programs_to_check; do
    u_test_program_is_executable "$p"
    assertTrue \
      "The program or alias '$p' appears to be missing (or is not executable) on current host or instance." \
      "[ $? -eq 0 ]"
  done
}

# Load and run shUnit2.
. cwt/vendor/shunit2/shunit2
