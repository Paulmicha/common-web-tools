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
#   - D4D_SETTINGS_GLOBALS
#   - and all the globals listed in D4D_SETTINGS_GLOBALS
#
# To list all the possible paths that can be used, use :
# $ make hook-debug s:app a:drupal_settings c:tpl.php v:DRUPAL_VERSION HOST_TYPE INSTANCE_TYPE
#
# To check the most specific match (if any is found) :
# $ make hook-debug ms s:app a:drupal_settings c:tpl.php v:DRUPAL_VERSION HOST_TYPE INSTANCE_TYPE
#
u_d4d_write_local_settings() {
  local f
  local var_name
  local hook_most_specific_dry_run_match=''

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
      rm "$DRUPAL_LOCAL_SETTINGS"
    fi

    cp "$hook_most_specific_dry_run_match" "$DRUPAL_LOCAL_SETTINGS"

    # Replaces strings in settings file using our custom token naming convention.
    if [[ -n "$D4D_SETTINGS_GLOBALS" ]]; then
      for var_name in $D4D_SETTINGS_GLOBALS; do
        u_str_sanitize_var_name "$var_name" 'var_name'
        eval "sed -e \"s,__replace_this_${var_name}_value__,\$${var_name},g\" -i $DRUPAL_LOCAL_SETTINGS"
      done
    fi
  fi
}
