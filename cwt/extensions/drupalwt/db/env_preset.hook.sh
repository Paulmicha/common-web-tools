#!/usr/bin/env bash

##
# Implements hook -s 'db' -a 'env_preset' -v 'HOST_TYPE INSTANCE_TYPE PROVISION_USING'.
#
# This hook is used to preset DB_* values by DB_ID, which is available in the
# calling scope of this hook.
# @see u_db_set()
#
# Every DB variable coming from u_dwt_sites() parsed YAML for given site ID
# serves as preset for u_db_set().
#

case "$DWT_MULTISITE" in true)
  u_dwt_sites "$DB_ID"
  u_db_vars_list
  for v in $db_vars_list; do
    dwt_sites_db_var="dwt_sites_${DB_ID}_db_$v"
    u_str_sanitize_var_name "$dwt_sites_db_var" 'dwt_sites_db_var'
    u_str_lowercase "$dwt_sites_db_var" dwt_sites_db_var
    eval "dwt_sites_db_var_isset=\"\${$dwt_sites_db_var+set}\""
    if [[ -n "$dwt_sites_db_var_isset" ]]; then
      export "DB_$v=${!dwt_sites_db_var}"
    fi
  done
esac
