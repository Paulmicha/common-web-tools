#!/usr/bin/env bash

##
# Aggregates dependencies.
#
# @see cwt/stack/init.sh
#

u_stack_get_specs "$PROJECT_STACK"

if [[ $P_VERBOSE == 1 ]]; then
  u_autoload_print_lookup_paths DEPS_LOOKUP_PATHS "Stack dependencies"
fi
