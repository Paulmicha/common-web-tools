#!/usr/bin/env bash

##
# Implements hook -s 'db' -a 'set_multi_db_ids' -v 'INSTANCE_TYPE'.
#
# In multi-site Drupal setups, add a DB_ID for each site (DB_ID = site_id).
#

case "$DWT_MULTISITE" in true)
  u_dwt_sites '*' 'ids_only'
  for site_id in "${dwt_sites_ids[@]}"; do
    multi_db_ids+=" $site_id"
  done
esac
