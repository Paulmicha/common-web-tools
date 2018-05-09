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
  local prioritized_lookups

  # prioritized_lookups="$PROJECT_SCRIPTS/"

  hook -s 'stack' -a 'docker-compose' -c "yml" -v 'DC_YML_VARIANTS' -t

  # TODO [wip] unfinished - this should create or override the file :
  # "$PROJECT_DOCROOT/docker-compose.yml" based on the most specific match.
  # for f in $inc_dry_run_files_list; do
  #   . "$f"
  # done
}
