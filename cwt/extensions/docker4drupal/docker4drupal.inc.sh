#!/usr/bin/env bash

##
# Docker4drupal utility functions.
#
# This file is sourced during core CWT bootstrap.
# @see cwt/bootstrap.sh
#
# Convention : functions names are all prefixed by "u" (for "utility").
#

##
# (re)Writes the DRUPAL_LOCAL_SETTINGS file in current project instance.
#
# Creates or override the 'settings.local.php' file for local project instance
# based on the most specific "template" match found.
#
# Also replaces custom "token" values using the following convention, e.g. :
# '__replace_this_DRUPAL_HASH_SALT_value__' becomes "$DRUPAL_HASH_SALT" (value).
#
# @requires the following globals in calling scope :
#   - DRUPAL_VERSION
#   - DRUPAL_LOCAL_SETTINGS
#
# To list all the possible paths that can be used, use :
# $ make hook-debug s:app a:drupal_settings c:tpl.php v:DRUPAL_VERSION HOST_TYPE INSTANCE_TYPE
#
# To check the most specific match (if any is found) :
# $ make hook-debug ms s:app a:drupal_settings c:tpl.php v:DRUPAL_VERSION HOST_TYPE INSTANCE_TYPE
#
u_d4d_write_local_settings() {
  local f
  local line
  local var_name
  local token_prefix='__replace_this_'
  local token_suffix='_value__'
  local hook_most_specific_dry_run_match=''

  echo "Rewrite Drupal local settings file ..."

  u_hook_most_specific 'dry-run' \
    -s 'app' \
    -a 'drupal_settings' \
    -c 'tpl.php' \
    -v 'DRUPAL_VERSION HOST_TYPE INSTANCE_TYPE' \
    -t

  # When we have found a match, (over)write in place + replace its "token" values.
  # @see cwt/extensions/docker4drupal/global.vars.sh
  if [[ -n "$hook_most_specific_dry_run_match" ]]; then
    if [[ -f "$DRUPAL_LOCAL_SETTINGS" ]]; then
      rm -f "$DRUPAL_LOCAL_SETTINGS"
    fi

    echo "... using template : '$hook_most_specific_dry_run_match' ..."

    cp "$hook_most_specific_dry_run_match" "$DRUPAL_LOCAL_SETTINGS"

    # Replaces strings in settings file using our custom token naming
    # convention. Works with any global variable name.
    u_global_list
    for var_name in "${cwt_globals_var_names[@]}"; do
      if grep -Fq "${token_prefix}${var_name}${token_suffix}" "$DRUPAL_LOCAL_SETTINGS"; then
        sed -e "s,${token_prefix}${var_name}${token_suffix},${!var_name},g" -i "$DRUPAL_LOCAL_SETTINGS"
        # echo "  replaced '${token_prefix}${var_name}${token_suffix}' by '${!var_name}'"
      fi
    done
  fi

  echo "Rewrite Drupal local settings file : done."
  echo
}
