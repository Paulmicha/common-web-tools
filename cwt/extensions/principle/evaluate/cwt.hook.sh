#!/usr/bin/env bash

##
# Implements hook -s 'test' -a 'cwt' -v 'HOST_TYPE PROVISION_USING'.
#
# Verifies current instance can execute docker-compose actions normally.
#
# @see u_test_batch_exec() in cwt/test/test.inc.sh
#
# @example
#   make test-cwt
#   # Or :
#   cwt/test/cwt.sh
#

# TODO scope conditions ? (instance type ? should be a more restrictive hook variant)
u_test_batch_exec 'cwt/extensions/principle/test/cwt'
