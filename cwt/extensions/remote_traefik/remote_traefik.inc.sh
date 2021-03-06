#!/usr/bin/env bash

##
# Remote Traefik utility functions.
#
# This file is sourced during core CWT bootstrap.
# @see cwt/bootstrap.sh
#
# Convention : functions names are all prefixed by "u" (for "utility").
#

##
# Generates local Acme config file for Let's Encrypt.
#
# To list matches & check which one will be used (the most specific) :
# $ p_site='my_site_id'
#   u_hook_most_specific 'dry-run' \
#     -s 'stack' \
#     -a 'traefik' \
#     -c 'tpl.yml' \
#     -v 'INSTANCE_TYPE' \
#     -t -d
#   echo "match = $hook_most_specific_dry_run_match"
#
u_traefik_generate_acme_conf() {
  local var_val
  local var_name
  local token_prefix='{{ '
  local token_suffix=' }}'
  local traefik_conf="$PROJECT_DOCROOT/scripts/cwt/local/traefik.yml"
  local hook_most_specific_dry_run_match=''

  u_hook_most_specific 'dry-run' \
    -s 'stack' \
    -a 'traefik' \
    -c 'tpl.yml' \
    -v 'INSTANCE_TYPE' \
    -t

  # No declaration file found ? Can't carry on, there's nothing to do.
  if [[ ! -f "$hook_most_specific_dry_run_match" ]]; then
    echo >&2
    echo "Error in u_traefik_generate_acme_conf() - $BASH_SOURCE line $LINENO: no settings template file was found." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    return 1
  fi

  # (Over)write config file in its final destination.
  if [[ -f "$traefik_conf" ]]; then
    rm -f "$traefik_conf"
  fi
  cp "$hook_most_specific_dry_run_match" "$traefik_conf"

  # Replace read-only global vars (supports any global) placeholders.
  u_global_list
  for var_name in "${cwt_globals_var_names[@]}"; do
    if grep -Fq "${token_prefix}${var_name}${token_suffix}" "$traefik_conf"; then
      var_val="${!var_name}"
      sed -e "s,${token_prefix}${var_name}${token_suffix},${var_val},g" -i "$traefik_conf"
      # Debug.
      # echo "replaced '${token_prefix}${var_name}${token_suffix}' by '${var_val}'"
    fi
  done

  # Special extra step : need to generate once scripts/cwt/local/acme.json
  if [[ ! -f "$PROJECT_DOCROOT/scripts/cwt/local/acme.json" ]]; then
    touch "$PROJECT_DOCROOT/scripts/cwt/local/acme.json"
  fi
}
