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
#   make globals-lp
#   # Or :
#   cwt/env/global_lookup_paths.make.sh
#

. cwt/bootstrap.sh

echo "cwt/env/global.vars.sh"

hook -a 'global' -c 'vars.sh' -v 'PROVISION_USING' -t -d

# Allow extra lookup paths at the root of extensions.
if [ -n "$CWT_EXTENSIONS" ]; then
  for extension in $CWT_EXTENSIONS; do
    ext_path=''
    u_cwt_extension_path "$extension"
    echo "$ext_path/$extension/global.vars.sh"
    if [ -f "$ext_path/$extension/global.vars.sh" ]; then
      echo "  exists"
    fi
  done
fi

echo
