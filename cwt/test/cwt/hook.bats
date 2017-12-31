#!/usr/bin/env bats

@test "Single action hook" {
  exit_code="$(cwt/test/cwt/hook.sh 'Single action hook')"
  [ -e $exit_code ]
}
