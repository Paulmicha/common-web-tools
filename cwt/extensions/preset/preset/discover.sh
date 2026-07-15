#!/usr/bin/env bash

##
# Catalog canonical / ideal CWT presets under cwt/extensions/preset/preset/.
#
# Prints greppable catalog lines:
#   path=... layer=... pack=... variants=... applies=yes|no tokens=...
#
# Optional filter arg: layer name (cwt-meta|subject|project) or pack name.
#
# @param 1 [optional] String : filter by layer or pack.
#
# @example
#   make preset-discover
#   # Or :
#   cwt/extensions/preset/preset/discover.sh
#
#   make preset-discover subject
#   make preset-discover cwt-meta
#   make preset-discover 11ty
#

. cwt/bootstrap.sh

u_preset_catalog || exit $?

filter="${1:-}"

while IFS= read -r line || [[ -n "$line" ]]; do
  [[ -z "$line" ]] && continue
  if [[ -n "$filter" ]]; then
    if [[ "$line" != *"layer=$filter"* && "$line" != *"pack=$filter"* ]]; then
      continue
    fi
  fi
  echo "$line"
done <<< "$preset_catalog_lines"
