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
# Creates or override the (docker-)compose.yml and (docker-)compose.override.yml
# files for local project instance based on the most specific match found.
#
# @requires the DC_YML_VARIANTS global in calling scope.
# @see cwt/extensions/docker-compose/global.vars.sh
#
# To list all the possible paths that can be used, use :
# $ make hook-debug s:stack a:docker-compose c:yml v:DC_YML_VARIANTS
# $ make hook-debug s:stack a:docker-compose.override c:yml v:DC_YML_VARIANTS
#
# To check which YAML file will actually be selected, use :
# $ make hook-debug ms s:stack a:docker-compose c:yml v:DC_YML_VARIANTS
# $ make hook-debug ms s:stack a:docker-compose.override c:yml v:DC_YML_VARIANTS
#
# By default, Compose reads two files, a docker-compose.yml and an optional
# docker-compose.override.yml file. By convention, the docker-compose.yml
# contains your base configuration. The override file, as its name implies,
# can contain configuration overrides for existing services or entirely new
# services.
# If a service is defined in both files, Compose merges the configurations
# using the following rules :
# - If a configuration option is defined in both the original service and the
#   local service, the local value replaces or extends the original value.
# - For single-value options like image, command or mem_limit, the new value
#   replaces the old value.
# - For the multi-value options ports, expose, external_links, dns, dns_search,
#   and tmpfs, Compose concatenates both sets of values.
# - In the case of environment, labels, volumes, and devices, Compose “merges”
#   entries together with locally-defined values taking precedence. For
#   environment and labels, the environment variable or label name determines
#   which value is used.
# - Entries for volumes and devices are merged using the mount path in the
#   container.
#
# @link https://docs.docker.com/compose/extends/#adding-and-overriding-configuration
#
u_dc_write_yml() {
  local f
  local hook_most_specific_dry_run_match=''

  # Update 2024 : docker-compose.yml can now be named compose.yml. Same with the
  # override file.
  local compose_file
  local compose_name
  local lookup='compose docker-compose compose.override docker-compose.override'

  if [[ -n "$DC_YML_LOOKUP" ]]; then
    lookup="$DC_YML_LOOKUP"
  fi

  # Do both compose + compose.override in one loop.
  for compose_name in $lookup; do
    compose_file="$compose_name.yml"
    hook_most_specific_dry_run_match=''

    # Debug.
    # hook -s 'stack' -a "$compose_name" -c "yml" -v 'DC_YML_VARIANTS' -t -r -d

    # Remove existing files if previously generated.
    if [[ -f "$compose_file" ]]; then
      rm "$compose_file"
    fi

    u_hook_most_specific 'dry-run' -s 'stack' -a "$compose_name" -c "yml" -v 'DC_YML_VARIANTS' -t

    if [[ -n "$hook_most_specific_dry_run_match" ]]; then
      echo "Generating $compose_file file (from $hook_most_specific_dry_run_match) ..."

      cp "$hook_most_specific_dry_run_match" "$compose_file"

      echo "Generating $compose_file file (from $hook_most_specific_dry_run_match) : done."
    fi
  done
}
