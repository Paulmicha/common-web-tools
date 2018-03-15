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
  echo "Executing CWT core $test_script ..."
  cwt/test/cwt/$test_script
  echo "Executing CWT core $test_script : done."
  echo
done
