#!/usr/bin/env bash

##
# CWT instance globals introspection for convenience 'make' task.
#
# Prints all globals lookup paths checked for aggregation during instance init
# for current project instance.
#
# @see Makefile
#
# @example
#   cwt/env/global_lookup_paths.make.sh
#

. cwt/bootstrap.sh

hook -a 'global' -c 'vars.sh' -v 'PROVISION_USING' -t -d
