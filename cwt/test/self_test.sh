#!/usr/bin/env bash

##
# CWT test self_test action.
#
# This generic implementation is meant for providing self-checking tests
# concerning current project instance whose services may not necessarily be
# running. For automated tests aimed at deployment / at runtime, see
# $DEPLOY_USING-related hooks instead (e.g. git).
#
# @see hook()
#
# @example
#   cwt/test/self_test.sh
#

. cwt/bootstrap.sh
. cwt/test/self_test.inc.sh

hook -s 'test' -a 'self_test' -v 'HOST_TYPE PROVISION_USING'