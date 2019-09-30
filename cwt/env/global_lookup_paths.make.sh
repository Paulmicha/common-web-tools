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

echo ""
echo "List of globals' aggregation paths that would be loaded, in this order, during instance (re)init :"
echo ""

echo "cwt/env/global.vars.sh"
echo "  exists"

# 1. Files named without variant (i.e. 'global.vars.sh')
hook -a 'global' -c 'vars.sh' -t -d
# ... including extra lookup paths at the root of extensions' folders.
if [ -n "$CWT_EXTENSIONS" ]; then
  for extension in $CWT_EXTENSIONS; do
    ext_path=''
    u_cwt_extension_path "$extension"
    echo "$ext_path/$extension/global.vars.sh "
    if [ -f "$ext_path/$extension/global.vars.sh" ]; then
      echo "  exists"
    fi
  done
fi

# 2. Files using variant in their name (i.e. 'global.docker-compose.vars.sh')
hook -a 'global' -c "${PROVISION_USING}.vars.sh" -t -d
if [ -n "$CWT_EXTENSIONS" ]; then
  for extension in $CWT_EXTENSIONS; do
    ext_path=''
    u_cwt_extension_path "$extension"
    echo "$ext_path/$extension/global.${PROVISION_USING}.vars.sh "
    if [ -f "$ext_path/$extension/global.${PROVISION_USING}.vars.sh" ]; then
      echo "  exists"
    fi
  done
fi

echo
