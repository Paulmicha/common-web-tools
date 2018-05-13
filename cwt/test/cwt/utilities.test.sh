#!/usr/bin/env bash

##
# CWT core generic utilities tests.
#
# @requires cwt/vendor/shunit2
#
# This file may be dynamically executed.
# @see cwt/test/cwt.sh
#
# @example
#   cwt/test/cwt/utilities.test.sh
#

. cwt/bootstrap.sh

##
# Basic string sanitizing test.
#
test_u_str_sanitize() {
  local sanitized_str
  local expected_output

  sanitized_str=''
  u_str_sanitize 'test space'
  expected_output='test-space'
  assertEquals 'u_str_sanitize() simple space test failed.' "$expected_output" "$sanitized_str"

  sanitized_str=''
  u_str_sanitize 'custom replacement: underscore' '_'
  expected_output='custom_replacement__underscore'
  assertEquals 'u_str_sanitize() custom replacement: underscore test failed.' "$expected_output" "$sanitized_str"

  sanitized_str=''
  u_str_sanitize 'custom replacement: empty string' ''
  expected_output='customreplacementemptystring'
  assertEquals 'u_str_sanitize() custom replacement: empty string test failed.' "$expected_output" "$sanitized_str"

  sanitized_str=''
  u_str_sanitize "test&special@chars#with|numbers^123~and[brackets]and\\backslashes\$and/slashes+plus quotes'single'and\"double\""
  expected_output='test-special-chars-with-numbers-123-and-brackets-and-backslashes-and-slashes-plus-quotes-single-and-double-'
  assertEquals 'u_str_sanitize() special chars test failed.' "$expected_output" "$sanitized_str"
}

# Load and run shUnit2.
. cwt/vendor/shunit2/shunit2
