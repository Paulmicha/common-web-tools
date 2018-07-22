#!/usr/bin/env bash

##
# Implements hook -s 'test' -a 'self_test' -v 'HOST_TYPE PROVISION_USING'.
#
# Runs CWT core tests (checks CWT itself). Verifies that the generic CWT
# functions can successfully run on current host.
#
# @requires running the tests with the same user that will use CWT.
#
# @see u_test_batch_exec() in cwt/test/test.inc.sh
#
# @example
#   make self-test
#   # Or :
#   cwt/test/self_test.sh
#

u_test_batch_exec 'cwt/test/cwt'
