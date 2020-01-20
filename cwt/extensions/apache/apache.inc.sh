#!/usr/bin/env bash

##
# Apache web server utility functions.
#
# This file is sourced during core CWT bootstrap.
# @see cwt/bootstrap.sh
#
# Convention : functions names are all prefixed by "u" (for "utility").
#

##
# (re)Writes Apache VHost config, (re)enable it, and reload Apache config.
#
# Creates or override the *.conf file for local project instance
# based on the most specific "template" match found.
#
# Also replaces custom "token" values using the following convention, e.g. :
# '{{ INSTANCE_DOMAIN }}' becomes "$INSTANCE_DOMAIN" (value).
#
# To list all the possible paths that can be used, use :
# $ make hook-debug s:config a:apache_vhost c:tpl.conf v:HOST_TYPE INSTANCE_TYPE INSTANCE_DOMAIN
#
# To check the most specific match (if any is found) :
# $ make hook-debug ms s:config a:apache_vhost c:tpl.conf v:HOST_TYPE INSTANCE_TYPE INSTANCE_DOMAIN
#
u_apache_write_vhost_conf() {
  local f
  local line
  local var_val
  local var_name
  local var_name_c
  local token_prefix='{{ '
  local token_suffix=' }}'
  local hook_most_specific_dry_run_match=''
  local generated_vhost_filepath="/etc/apache2/sites-available/${INSTANCE_DOMAIN}.conf"

  echo "(Re)write Apache VHost config ..."

  u_hook_most_specific 'dry-run' \
    -s 'config' \
    -a 'apache_vhost' \
    -c 'tpl.conf' \
    -v 'HOST_TYPE INSTANCE_TYPE INSTANCE_DOMAIN' \
    -t

  # When we have found a match, (over)write in place + replace its "token" values.
  # @see cwt/extensions/drupalwt/global.vars.sh
  if [[ -n "$hook_most_specific_dry_run_match" ]]; then
    if [[ -f "$generated_vhost_filepath" ]]; then
      rm -f "$generated_vhost_filepath"
    fi

    echo "... using template : '$hook_most_specific_dry_run_match' ..."

    cp "$hook_most_specific_dry_run_match" "$generated_vhost_filepath"

    # Replaces strings in settings file using our custom token naming
    # convention. Works with any global variable name.
    u_global_list
    for var_name in "${cwt_globals_var_names[@]}"; do
      if grep -Fq "${token_prefix}${var_name}${token_suffix}" "$generated_vhost_filepath"; then
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

        sed -e "s,${token_prefix}${var_name}${token_suffix},${var_val},g" -i "$generated_vhost_filepath"
        # echo "  replaced '${token_prefix}${var_name}${token_suffix}' by '${var_val}'"
      fi
    done

    # DB credentials may not all be declared using (readonly) globals, and there
    # may be distinct databases using a "modifier" scoped variable.
    # @see u_db_set()
    # -> For projects using multiple databases, the distinction is made using
    # the following convention : prefix var names using $DB_ID, e.g. :
    # in the settings template, use {{ DEFAULT_DB_USER }}.
    local db_vars='DB_DRIVER DB_HOST DB_PORT DB_NAME DB_USER DB_PASS'
    local db_vars_backup="$db_vars"
    local cwt_db_id=""
    for cwt_db_id in $CWT_DB_IDS; do
      u_str_uppercase "$cwt_db_id" 'cwt_db_id'
      for var_name in $db_vars_backup; do
        db_vars+=" ${cwt_db_id}_${var_name}"
      done
    done
    for var_name in $db_vars; do
      if grep -Fq "${token_prefix}${var_name}${token_suffix}" "$generated_vhost_filepath"; then
        sed -e "s,${token_prefix}${var_name}${token_suffix},${!var_name},g" -i "$generated_vhost_filepath"
        # echo "  replaced '${token_prefix}${var_name}${token_suffix}' by '${!var_name}'"
      fi
    done
  fi

  # Only enable if corresponding symlink is not found.
  local vhost_symlink="/etc/apache2/sites-enabled/${INSTANCE_DOMAIN}.conf"
  if [[ ! -L "$vhost_symlink" ]]; then
    a2ensite "$INSTANCE_DOMAIN"
    if [[ $? -ne 0 ]]; then
      echo >&2
      echo "Error in $BASH_SOURCE line $LINENO: unable to activate Apache vhost '$generated_vhost_filepath'." >&2
      echo "-> Aborting (1)." >&2
      echo >&2
      exit 1
    fi
  fi

  # Always reload (in case of any update to the VHost file that was just
  # overwritten).
  apache2_reload

  echo "(Re)write Apache VHost config : done."
  echo
}

##
# Reload Apache 2 configuration only if valid.
#
# See https://github.com/biapy/howto.biapy.com/blob/master/apache2/a2tools
#
apache2_reload() {
  if apache2ctl -t > /dev/null 2>&1; then
    if [ -n "$(which 'service')" ]; then
      service 'apache2' 'reload'
    else
      /etc/init.d/apache2 'reload'
    fi
  else
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO: Apache 2 configuration invalid. Reload cancelled." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    exit 1
  fi
}
