#!/usr/bin/env bash

##
# [abstract] Installs application instance on current host.
#
# The "app install" action is meant to setup the application if it requires
# e.g. some settings file to be generated, a database to be initialiazed, some
# DB dump to be imported, etc.
#
# This script provides an entry point for triggering a specific hook. "Abstract"
# means that CWT core itself doesn't provide any actual implementation for this
# functionality. In order for this script to have any effect, it is necessary
# to use an extension that does.
#
# @prereq stack services must be running (see 'instance start' action).
# @see cwt/instance/start.sh
#
# @example
#   make app-install
#   # Or :
#   cwt/app/install.sh
#

. cwt/bootstrap.sh

hook -s 'app' -a 'install' -v 'PROVISION_USING INSTANCE_TYPE'
