#!/usr/bin/env bash

##
# Docker-compose stack-related utility functions.
#
# This file is sourced during core CWT bootstrap.
# @see cwt/bootstrap.sh
#
# Convention : functions names are all prefixed by "u" (for "utility").
#

##
# Gets the docker-compose.yml file template to use in current project instance.
#
# @requires global DC_YML_VARIANTS in calling scope.
# @see cwt/extensions/docker-compose/global.vars.sh
#
u_stack_template() {
  local f
  local inc_dry_run_files_list

  hook -a 'docker-compose' -c "yml" -v 'DC_YML_VARIANTS' -t -d

  for f in $inc_dry_run_files_list; do
    . "$f"
  done
}
