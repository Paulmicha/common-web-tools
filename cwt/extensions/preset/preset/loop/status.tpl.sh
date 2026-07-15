#!/usr/bin/env bash

##
# Report systemd --user loop instances (registry + is-active).
#
# This file is generated from template :
# @see {{ TEMPLATE }}
#
# @example
#   make loop-status
#   make loop-status e:agent-loop
#

. cwt/bootstrap.sh

u_hook_most_specific 'dry-run' -s 'loop' -a 'monitor' \
  -v 'STACK_VERSION PROVISION_USING HOST_TYPE HOST_OS'
if [[ -n "${hook_most_specific_dry_run_match:-}" && -f "$hook_most_specific_dry_run_match" ]]; then
  # shellcheck disable=SC1090
  . "$hook_most_specific_dry_run_match" "${1:-}"
else
  echo >&2 "Error: no loop/monitor hook."
  exit 1
fi
