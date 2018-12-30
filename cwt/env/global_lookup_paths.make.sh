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

# Allow extra lookup paths at the root of extensions.
if [ -n "$CWT_EXTENSIONS" ]; then
  for extension in $CWT_EXTENSIONS; do
    echo "cwt/extensions/$extension/global.vars.sh"
    if [ -f "cwt/extensions/$extension/global.vars.sh" ]; then
      echo "  exists"
    fi
  done
fi

# Allow extra lookup path at the root of project's scripts, *after* all
# dynamic lookups above.
echo "$PROJECT_SCRIPTS/global.vars.sh"
if [ -f "$PROJECT_SCRIPTS/global.vars.sh" ]; then
  echo "  exists"
fi

echo
