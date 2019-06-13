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
# Generates the default value used for container names to match traefik labels.
#
# @see cwt/extensions/docker-compose/global.vars.sh
#
# @example
#   default_namespace=$(u_dc_default_namespace)
#   echo "$default_namespace" # <- prints instance domain stripped of all non-alphanumerical characters.
#
u_dc_default_namespace() {
  local namespace="$INSTANCE_DOMAIN"
  u_str_sanitize_var_name "$namespace" 'namespace'
  echo "${namespace//_/''}"
}

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
# $ make hook-debug s:stack a:docker-compose.override c:yml v:DC_YML_VARIANTS
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
  # See https://docs.docker.com/compose/extends/#adding-and-overriding-configuration
  hook_most_specific_dry_run_match=''

  if [[ -z "$DC_OVERRIDE_YML" ]]; then
    DC_OVERRIDE_YML='docker-compose.override.yml'
  fi

  u_hook_most_specific 'dry-run' -s 'stack' -a 'docker-compose.override' -c "yml" -v 'DC_YML_VARIANTS' -t

  if [ -n "$hook_most_specific_dry_run_match" ]; then
    if [ -f "$DC_OVERRIDE_YML" ]; then
      rm "$DC_OVERRIDE_YML"
    fi
    cp "$hook_most_specific_dry_run_match" "$DC_OVERRIDE_YML"
  fi
}
