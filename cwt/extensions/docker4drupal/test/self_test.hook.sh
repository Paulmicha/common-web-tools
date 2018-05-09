#!/usr/bin/env bash

##
# Implements hook -s 'test' -a 'self_test' -v 'HOST_TYPE PROVISION_USING'.
#
# Run CWT docker4drupal extension tests (checks the extension itself).
#
# This file is dynamically included when the "hook" is triggered.
# @see cwt/test/self_test.sh
#

. cwt/bootstrap.sh

# TODO [wip] refacto in progress.
