#!/usr/bin/env bash

##
# List presets that apply on the current host (host-filtered catalog).
#
# Slice of preset-discover where applies=yes — what preset-write defaults
# would use.
#
# @example
#   make preset-list
#   # Or :
#   cwt/extensions/preset/preset/list.sh
#

. cwt/bootstrap.sh

u_preset_list || exit $?

echo "Presets applying now (HOST_OS=$HOST_OS HOST_TYPE=$HOST_TYPE PROVISION_USING=$PROVISION_USING INSTANCE_TYPE=$INSTANCE_TYPE):"
echo

while IFS= read -r line || [[ -n "$line" ]]; do
  [[ -z "$line" ]] && continue
  echo "$line"
done <<< "$preset_list_lines"
