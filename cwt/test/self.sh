#!/usr/bin/env bash

##
# Run CWT core tests (checks CWT itself).
#
# Verifies that the generic CWT functions can successfully run on current host.
#
# @requires running the tests with the same user that will use CWT.
#
# @example
#   cwt/test/self.sh
#

. cwt/bootstrap.sh

u_fs_file_list cwt/test/cwt '*.test.sh'

for test_script in $file_list; do
  echo "# Executing CWT core $test_script ..."

  # Execute shunit2 test case.
  # See https://github.com/kward/shunit2
  cwt/test/cwt/$test_script

  # Do not carry on if a test failed in current test case.
  if [[ $? -ne 0 ]]; then
    echo >&2
    echo "The test case '$test_script' did not pass" >&2
    echo "-> aborting (see details above)." >&2
    echo >&2
    echo "# Executing CWT core $test_script : done."
    echo
    break
  fi

  echo "# Executing CWT core $test_script : done."
  echo
done
