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
#   make self-test
#   cwt/test/self_test.sh
#   cwt/extensions/mysql/test/mysql/required_programs.test.sh
#

. cwt/bootstrap.sh

##
# Can we use the 'mysql' command from this instance ?
#
test_mysql_cmd() {
  local check=0
  if ! [ -x "$(command -v mysql)" ]; then
    check=1
  fi
  assertTrue \
    "The program or alias 'mysql' appears to be missing (or is not executable) on current host or instance." \
    "[ $check -eq 0 ]"
}

##
# Can we use the 'mysqldump' command from this instance ?
#
test_mysqldump_cmd() {
  local check=0
  if ! [ -x "$(command -v mysqldump)" ]; then
    check=1
  fi
  assertTrue \
    "The program or alias 'mysqldump' appears to be missing (or is not executable) on current host or instance." \
    "[ $check -eq 0 ]"
}

# Load and run shUnit2.
. cwt/vendor/shunit2/shunit2
