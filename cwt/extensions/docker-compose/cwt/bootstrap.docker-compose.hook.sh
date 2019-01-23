#!/usr/bin/env bash

##
# Implements hook -s 'cwt' -a 'bootstrap' -v 'PROVISION_USING'.
#
# Implement custom bash alias for the 'docker-compose' program given 'DC_MODE'
# value, which specifies if and how docker-compose will choose a YAML
# declaration file for current project instance.
#
# @see cwt/extensions/docker-compose/global.vars.sh
# @see cwt/bootstrap.sh
#

case "$DC_MODE" in

  # Automatically try to choose the most specific YAML file based on the
  # DC_YML_VARIANTS global (which provides hook variants for lookup paths).
  'auto')
    hook_most_specific_dry_run_match=''
    u_hook_most_specific 'dry-run' -s 'stack' -a 'docker-compose' -c "yml" -v 'DC_YML_VARIANTS' -t

    if [ -f "$hook_most_specific_dry_run_match" ]; then
      alias docker-compose="docker-compose -f $hook_most_specific_dry_run_match"
    fi
    ;;

  # Use the path provided in the DC_YML global.
  'manual')
    if [[ -f "$DC_YML" ]]; then
      alias docker-compose="docker-compose -f $DC_YML"
    fi
    ;;
esac
