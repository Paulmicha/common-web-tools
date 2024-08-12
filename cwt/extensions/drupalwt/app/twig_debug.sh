#!/usr/bin/env bash

##
# Activate twig debug (supports multi-site).
#
# @example
#   # Enable Twig debug mode (switch on) :
#   make app-twig-debug
#   # Or :
#   cwt/extensions/drupalwt/app/twig_debug.sh
#

. cwt/bootstrap.sh

echo "Switching on Twig debug mode..."

case "$DWT_MULTISITE" in
  # Multi-site support.
  true)
    u_dwt_sites
    for site_id in "${dwt_sites_ids[@]}"; do
      u_str_sanitize_var_name "$site_id" 'site_id'
      var="dwt_sites_${site_id}_dir"
      site_dir="${!var}"
      chmod u+w "$SERVER_DOCROOT/sites/$site_dir"
      cp -f 'cwt/extensions/drupalwt/app/services.twig_debug.yml' \
        "$SERVER_DOCROOT/sites/$site_dir/services.yml"
      chmod u-w "$SERVER_DOCROOT/sites/$site_dir"
    done

    drush_ms cr
    ;;

  # "Normal" setups : only deal with the 'default' site dir.
  *)
    chmod u+w "$SERVER_DOCROOT/sites/default"
    cp -f 'cwt/extensions/drupalwt/app/services.twig_debug.yml' \
      "$SERVER_DOCROOT/sites/default/services.yml"
    chmod u-w "$SERVER_DOCROOT/sites/default"
    drush cr
    ;;
esac

echo "Switching on Twig debug mode : done."
