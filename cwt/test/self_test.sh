#!/usr/bin/env bash

##
# CWT test self_test action.
#
# This generic implementation is meant for providing self-checking tests
# concerning current project instance whose services may not necessarily be
# running.
#
# @see hook()
#
# @example
#   cwt/test/self_test.sh
#

. cwt/bootstrap.sh

hook -s 'test' -a 'self_test' -v 'HOST_TYPE PROVISION_USING'
