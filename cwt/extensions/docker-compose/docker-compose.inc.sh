#!/usr/bin/env bash

##
# Docker-compose utility functions.
#
# This file is sourced during core CWT bootstrap.
# @see cwt/bootstrap.sh
#
# Convention : functions names are all prefixed by "u" (for "utility").
#

##
# (re)Writes the docker-compose.yml file to use in current project instance.
#
# Creates or override the docker-compose.yml file for local project instance
# based on the most specific match found.
#
# @requires the DC_YML_VARIANTS global in calling scope.
# @see cwt/extensions/docker-compose/global.vars.sh
#
# To list all the possible paths that can be used, use :
# $ make hook-debug s:stack a:docker-compose c:yml v:DC_YML_VARIANTS
#
u_dc_write_yml() {
  local f
  local hook_most_specific_dry_run_match=''

  if [[ -z "$DC_YML" ]]; then
    DC_YML='docker-compose.yml'
  fi

  u_hook_most_specific 'dry-run' -s 'stack' -a 'docker-compose' -c "yml" -v 'DC_YML_VARIANTS' -t

  if [ -n "$hook_most_specific_dry_run_match" ]; then
    if [ -f "$DC_YML" ]; then
      rm "$DC_YML"
    fi
    cp "$hook_most_specific_dry_run_match" "$DC_YML"
  fi
}
