#!/usr/bin/env bash

##
# [abstract] Installs application instance on current host.
#
# The "app install" action is meant to setup the application if it requires
# e.g. some settings file to be generated, a database to be initialized, some
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
# This 'app install' action triggers a 'pre'-prefixed hook before triggering the
# normal (unprefixed) hook. Same after ('post'-prefixed hook).
#
# To list all the possible paths that can be used among which existing files
# will be sourced when the hook is triggered, run (in this order) :
# $ make hook-debug s:app p:pre a:install v:PROVISION_USING INSTANCE_TYPE
# $ make hook-debug s:app a:install v:PROVISION_USING INSTANCE_TYPE
# $ make hook-debug s:app p:post a:install v:PROVISION_USING INSTANCE_TYPE
#
# @example
#   make app-install
#   # Or :
#   cwt/app/install.sh
#

. cwt/bootstrap.sh

hook -s 'app' -p 'pre' -a 'install' -v 'PROVISION_USING INSTANCE_TYPE'
hook -s 'app' -a 'install' -v 'PROVISION_USING INSTANCE_TYPE'
hook -s 'app' -p 'post' -a 'install' -v 'PROVISION_USING INSTANCE_TYPE'
