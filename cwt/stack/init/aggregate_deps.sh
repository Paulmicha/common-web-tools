#!/bin/bash

##
# Aggregates dependencies.
#
# @see cwt/stack/init.sh
#

u_stack_resolve_deps

if [[ $P_VERBOSE == 1 ]]; then
  u_autoload_print_lookup_paths DEPS_LOOKUP_PATHS "Stack dependencies"
fi
