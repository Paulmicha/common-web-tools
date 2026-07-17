#!/usr/bin/env bash

##
# Implements hook -s 'host' -a 'provision' -v 'HOST_OS HOST_TYPE PROVISION_USING'
#
# Personal tools: load YAML manifests → status diff → apply install/upgrade.
# Uninstall only when SOFTWARE_PRUNE=1 (opt-in).
#
# Helpers come from provision.opt-inc.sh (seeded into the hook cache before this
# file is sourced — see u_hook_opt_inc_append_candidates).
#
# @see cwt/host/provision.sh
# @see cwt/extensions/software/host/provision.opt-inc.sh
#
# @example
#   make host-provision
#   SOFTWARE_PRUNE=1 make host-provision
#

u_software_provision apply
