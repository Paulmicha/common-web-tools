#!/usr/bin/env bash

##
# Test-related utility functions.
#
# This file is sourced during core CWT bootstrap.
# @see cwt/bootstrap.sh
#
# Convention : functions names are all prefixed by "u" (for "utility").
#

##
# Executes a series of tests dynamically loaded from given dir.
#
# @requires that the folder contains files using the double extension pattern :
# *.test.sh
#
# @param 1 String : path to folder containing test cases.
#
# @example
#   u_test_batch_exec cwt/extensions/mysql/test/mysql
#
u_test_batch_exec() {
  local p_dir="$1"

  if [[ ! -d "$p_dir" ]]; then
    echo >&2
    echo "Error in u_test_batch_exec() - $BASH_SOURCE line $LINENO: the '$p_dir' folder is missing or inaccessible." >&2
    echo "-> Aborting." >&2
    echo >&2
    exit 1
  fi

  u_fs_file_list "$p_dir" '*.test.sh'

  for test_script in $file_list; do
    echo "# Executing $p_dir/$test_script ..."

    # Execute shunit2 test case.
    # See https://github.com/kward/shunit2
    $p_dir/$test_script

    # Do not carry on if a test failed in current test case.
    if [[ $? -ne 0 ]]; then
      echo >&2
      echo "The test case '$test_script' did not pass" >&2
      echo "-> aborting (see details above)." >&2
      echo >&2
      echo "# Executing $p_dir/$test_script : done."
      echo
      break
    fi

    echo "# Executing $p_dir/$test_script : done."
    echo
  done
}

##
# Tests if given program or alias is executable from current instance.
#
# @param 1 String : the program to test.
# @return Int : 0 if OK, or 1 if program was not found or not executable.
#
# @example
#   u_test_program_is_executable 'git'
#
u_test_program_is_executable() {
  local p_program="$1"
  local check=0

  if [[ "$(type -t $p_program)" == 'alias' ]]; then
    # TODO [fail] there seems to be no reliable way to test if an alias can run
    # successfully. Meanwhile, we assume that if an alias is found, it will be
    # executable.
    check=0
  elif ! [ -x "$(command -v $p_program)" ]; then
    check=1
  fi

  return $check
}
