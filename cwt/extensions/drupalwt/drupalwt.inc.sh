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
# '{{ DRUPAL_HASH_SALT }}' becomes "$DRUPAL_HASH_SALT" (value).
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
u_dwt_write_local_settings() {
  local f
  local line
  local var_val
  local var_name
  local var_name_c
  local token_prefix='{{ '
  local token_suffix=' }}'
  local hook_most_specific_dry_run_match=''

  echo "(Re)write Drupal local settings file ..."

  u_hook_most_specific 'dry-run' \
    -s 'app' \
    -a 'drupal_settings' \
    -c 'tpl.php' \
    -v 'DRUPAL_VERSION HOST_TYPE INSTANCE_TYPE' \
    -t

  # When we have found a match, (over)write in place + replace its "token" values.
  # @see cwt/extensions/drupalwt/global.vars.sh
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
        var_val="${!var_name}"

        # Docker-compose specific : container paths are different, and CWT needs
        # both -> use variable name convention : if a variable named like the
        # current one with a '_C' suffix, it will automatically be used instead.
        # TODO [evol] Caveat : does not work if suffixed var value is empty.
        # @see cwt/extensions/drupalwt/app/global.docker-compose.vars.sh
        case "$PROVISION_USING" in docker-compose)
          var_name_c="${var_name}_C"
          if [[ -n "${!var_name_c}" ]]; then
            var_val="${!var_name_c}"
          fi
        esac

        sed -e "s,${token_prefix}${var_name}${token_suffix},${var_val},g" -i "$DRUPAL_LOCAL_SETTINGS"
        # echo "  replaced '${token_prefix}${var_name}${token_suffix}' by '${var_val}'"
      fi
    done

    # DB credentials may not all be declared using (readonly) globals, and there
    # may be distinct databases using a "modifier" scoped variable.
    # @see u_db_get_credentials()
    # -> For projects using multiple databases, the distinction is made using
    # the following convention : prefix var names using $DB_ID, e.g. :
    # in the settings template, use {{ default_DB_USERNAME }}.
    local db_vars='DB_NAME DB_USERNAME DB_PASSWORD DB_HOST DB_PORT'
    local db_vars_backup="$db_vars"
    for CWT_DB_ID in $CWT_DB_IDS; do
      for var_name in $db_vars_backup; do
        db_vars+=" ${CWT_DB_ID}_${var_name}"
      done
    done
    for var_name in $db_vars; do
      if grep -Fq "${token_prefix}${var_name}${token_suffix}" "$DRUPAL_LOCAL_SETTINGS"; then
        sed -e "s,${token_prefix}${var_name}${token_suffix},${!var_name},g" -i "$DRUPAL_LOCAL_SETTINGS"
        # echo "  replaced '${token_prefix}${var_name}${token_suffix}' by '${!var_name}'"
      fi
    done
  fi

  echo "(Re)write Drupal local settings file : done."
  echo
}
