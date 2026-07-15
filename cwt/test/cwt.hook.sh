#!/usr/bin/env bash

##
# Implements hook -s 'test' -a 'cwt' -v 'HOST_TYPE PROVISION_USING'.
#
# Runs CWT core low-level tests (checks CWT itself). Verifies that generic CWT
# functions can successfully run on the current host.
#
# @requires running the tests with the same user that will use CWT.
#
# @see u_test_batch_exec() in cwt/test/test.inc.sh
#
# @example
#   make test-cwt
#   # Or :
#   cwt/test/cwt.sh
#

u_test_batch_exec 'cwt/test/cwt' || exit $?
