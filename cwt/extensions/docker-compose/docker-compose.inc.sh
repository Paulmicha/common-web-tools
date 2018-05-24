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
# Gets the docker-compose.yml file template to use in current project instance.
#
# Creates or override the docker-compose.yml file for local project instance
# based on the most specific match found.
#
# @requires the following globals in calling scope :
#   - DC_YML
#   - DC_YML_VARIANTS
#
# @see cwt/extensions/docker-compose/global.vars.sh
#
u_dc_template() {
  local f
  local hook_most_specific_dry_run_match=''

  u_hook_most_specific 'dry-run' -s 'stack' -a 'docker-compose' -c "yml" -v 'DC_YML_VARIANTS' -t

  if [ -n "$hook_most_specific_dry_run_match" ]; then
    if [ -f "$DC_YML" ]; then
      rm "$DC_YML"
    fi
    cp "$hook_most_specific_dry_run_match" "$DC_YML"
  fi
}
