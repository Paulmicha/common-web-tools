#!/usr/bin/env bats

setup() {
  . cwt/bootstrap.sh
}

@test "1. Single action hook" {
  # result="$(hook -a 'bootstrap')"
  # [ -n "$result" ]
  run hook -a 'bootstrap'
  my_var="$CWT_INC"
  # result="test"
  # [ -n "$result" ]
  [ -n "$my_var" ]
}
