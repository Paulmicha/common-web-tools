#!/usr/bin/env bash

##
# CWT app install action.
#
# This generic implementation is meant to setup the application if it requires
# e.g. a database to be initialiazed, an initial DB dump to be imported, etc.
#
# It supports variants by :
# - PROVISION_USING
# - INSTANCE_TYPE
# @see hook()
#
# @prereq stack services must be running (see 'instance start' action).
# @see cwt/instance/start.sh
#
# @example
#   cwt/app/install.sh
#

. cwt/bootstrap.sh

hook -a 'install' -s 'app' -v 'PROVISION_USING INSTANCE_TYPE'
