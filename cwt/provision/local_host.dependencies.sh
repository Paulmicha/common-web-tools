#!/bin/bash

##
# Dependencies declaration.
#
# This file is dynamically included during stack init.
# @see u_stack_resolve_deps()
# @see u_stack_get_specs()
# @see cwt/stack/init.sh
#
# Matching rules and syntax are explained in documentation :
# @see cwt/env/README.md
#

declare -a instance_types_mailhog_arr=("dev" "test" "stage")
if u_in_array "$INSTANCE_TYPE" instance_types_mailhog_arr; then
  softwares+='mailhog'
fi
