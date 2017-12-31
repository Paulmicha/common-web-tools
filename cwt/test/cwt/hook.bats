#!/usr/bin/env bats

@test "1. Single action hook" {
  result="$(bash cwt/custom/debug.sh)"
  [ -n "$result" ]
}
