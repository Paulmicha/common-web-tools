#!/usr/bin/env bash

##
# CWT instance globals introspection for convenience 'make' task.
#
# Prints all globals lookup paths checked for aggregation during instance init
# for current project instance.
#
# @see Makefile
# @see cwt/make/default.mk
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
if [[ -n "$PROVISION_USING" ]]; then
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
fi

# 3. Using the env.yml method takes precedence.
echo
if [[ -n "$HOST_TYPE" ]] && [[ -n "$INSTANCE_TYPE" ]]; then
  hook -s 'instance' -a 'env' -c 'yml' -v 'HOST_TYPE INSTANCE_TYPE' -d -t
  echo "env.yml
env.$INSTANCE_TYPE.yml
env.$STACK_VERSION.yml
env.$HOST_TYPE.$INSTANCE_TYPE.yml
env.$STACK_VERSION.$HOST_TYPE.yml
env.$STACK_VERSION.$INSTANCE_TYPE.yml
env.$STACK_VERSION.$HOST_TYPE.$INSTANCE_TYPE.yml
.env-local.yml
.env-local.$HOST_TYPE.yml
.env-local.$INSTANCE_TYPE.yml
.env-local.$STACK_VERSION.yml
.env-local.$HOST_TYPE.$INSTANCE_TYPE.yml
.env-local.$STACK_VERSION.$HOST_TYPE.yml
.env-local.$STACK_VERSION.$INSTANCE_TYPE.yml
.env-local.$STACK_VERSION.$HOST_TYPE.$INSTANCE_TYPE.yml"
else
  echo "env.yml
.env-local.yml"
fi

echo
