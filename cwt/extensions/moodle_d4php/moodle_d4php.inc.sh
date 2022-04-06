#!/usr/bin/env bash

##
# Moodle utility functions.
#
# This file is sourced during core CWT bootstrap.
# @see cwt/bootstrap.sh
#
# Convention : functions names are all prefixed by "u" (for "utility").
#

##
# (Re)writes Moodle local settings files.
#
# Creates or override the 'config.php' file based on the most specific
# "template" match found.
#
# Also replaces custom "token" values using the following convention, e.g. :
# '{{ MOODLE_HASH_SALT }}' becomes "$MOODLE_HASH_SALT" (value).
#
# Uses the following global var in calling scope if available :
#   - MOODLE_VERSION
#
# To list matches & check which one will be used (the most specific) :
# $ u_hook_most_specific 'dry-run' \
#     -s 'app' \
#     -a 'config' \
#     -c 'tpl.php' \
#     -v 'MOODLE_VERSION HOST_TYPE INSTANCE_TYPE' \
#     -t -d
#   echo "match = $hook_most_specific_dry_run_match"
#
u_moodle_write_settings() {
  local f
  local line
  local var_val
  local var_name
  local var_name_c
  local token_prefix='{{ '
  local token_suffix=' }}'
  local hook_most_specific_dry_run_match=''

  # Moodle settings template variants allow using separate files by site ID.
  u_hook_most_specific 'dry-run' \
    -s 'app' \
    -a 'config' \
    -c 'tpl.php' \
    -v 'MOODLE_VERSION HOST_TYPE INSTANCE_TYPE' \
    -t

  # No declaration file found ? Can't carry on, there's nothing to do.
  if [[ ! -f "$hook_most_specific_dry_run_match" ]]; then
    echo >&2
    echo "Error in u_moodle_write_settings() - $BASH_SOURCE line $LINENO: no Moodle settings template file was found." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    return 1
  fi

  # Skip step if Moodle app codebase isn't initialized yet.
  if [[ ! -f "$SERVER_DOCROOT/index.php" ]]; then
    return
  fi

  # Console feedback.
  echo "(Re)write Moodle config file ($MOODLE_CONFIG_FILE) ..."
  echo "  using template : $hook_most_specific_dry_run_match ..."

  # Replace $MOODLE_CONFIG_FILE file with the matching template and replace its
  # "token" values.
  if [[ -f "$MOODLE_CONFIG_FILE" ]]; then
    rm -f "$MOODLE_CONFIG_FILE"
    if [[ $? -ne 0 ]]; then
      echo >&2
      echo "Error in u_moodle_write_drupal_settings() - $BASH_SOURCE line $LINENO: failed to replace the file '$MOODLE_CONFIG_FILE'." >&2
      echo "-> Aborting (3)." >&2
      echo >&2
      exit 3
    fi
  fi
  cp "$hook_most_specific_dry_run_match" "$MOODLE_CONFIG_FILE"
  if [[ $? -ne 0 ]]; then
    echo >&2
    echo "Error in u_moodle_write_drupal_settings() - $BASH_SOURCE line $LINENO: failed to copy template $hook_most_specific_dry_run_match to '$MOODLE_CONFIG_FILE'." >&2
    echo "-> Aborting (4)." >&2
    echo >&2
    exit 4
  fi

  # Start with read-only global vars (supports any global).
  u_global_list
  for var_name in "${cwt_globals_var_names[@]}"; do
    if grep -Fq "${token_prefix}${var_name}${token_suffix}" "$MOODLE_CONFIG_FILE"; then
      var_val="${!var_name}"

      # Docker-compose specific : container paths are different, and CWT needs
      # both -> use variable name convention : if a variable named like the
      # current one with a '_C' suffix, it will automatically be used instead.
      # TODO [evol] Caveat : does not work if suffixed var value is empty.
      # @see cwt/extensions/moodle_d4php/app/global.docker-compose.vars.sh
      case "$PROVISION_USING" in docker-compose)
        var_name_c="${var_name}_C"
        if [[ -n "${!var_name_c}" ]]; then
          var_val="${!var_name_c}"
        fi
      esac

      sed -e "s,${token_prefix}${var_name}${token_suffix},${var_val},g" -i "$MOODLE_CONFIG_FILE"
      # echo "  [$p_site] replaced '${token_prefix}${var_name}${token_suffix}' by '${var_val}'"
    fi
  done

  # Now, deal with DB-related variables (not necessarily globals). Any prefixed
  # or unprefixed DB_* var, including other site's, are supported everywhere.
  local unique_db_ids=()

  # First, reset unprefixed DB_* vars to default.
  u_db_set
  local v=''
  local site_id=''
  local db_vars=''
  u_db_vars_list
  for v in $db_vars_list; do
    db_vars+="DB_${v} "
  done

  # Multi-DB (manually set using the CWT_DB_IDS global) support.
  local db_id=''
  for db_id in $CWT_DB_IDS; do
    if u_in_array "$db_id" unique_db_ids; then
      continue
    fi
    unique_db_ids+=("$db_id")
    u_str_uppercase "$db_id" 'db_id'
    for v in $db_vars_list; do
      db_vars+="${db_id}_DB_${v} "
    done
  done

  # Now we're looping through all these possibilities and replace all matching
  # token(s), if any was found in the settings template used.
  for var_name in $db_vars; do
    if grep -Fq "${token_prefix}${var_name}${token_suffix}" "$MOODLE_CONFIG_FILE"; then
      sed -e "s,${token_prefix}${var_name}${token_suffix},${!var_name},g" -i "$MOODLE_CONFIG_FILE"
      # echo "  [$p_site] replaced '${token_prefix}${var_name}${token_suffix}' by '${!var_name}'"
    fi
  done

  # Keep write-protection.
  u_instance_get_permissions
  chmod "$FS_P_FILES" "$MOODLE_CONFIG_FILE"
  if [[ $? -ne 0 ]]; then
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO: chmod exited with non-zero status." >&2
    echo "-> Aborting (6)." >&2
    echo >&2
    exit 6
  fi

  echo "(Re)write Moodle config file ($MOODLE_CONFIG_FILE) : done."
  echo
}
