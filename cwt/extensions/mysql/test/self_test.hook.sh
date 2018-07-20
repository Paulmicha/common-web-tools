#!/usr/bin/env bash

##
# Implements hook -s 'test' -a 'self_test' -v 'HOST_TYPE PROVISION_USING'.
#
# Verifies current instance can execute MySQL actions normally.
#
# @see u_test_batch_exec() in cwt/test/test.inc.sh
#
# @example
#   make self-test
#   cwt/test/self_test.sh
#

u_test_batch_exec 'cwt/extensions/mysql/test/mysql'
