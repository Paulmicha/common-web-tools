#!/usr/bin/env bash

##
# Clears Moodle application cache.
#
# TODO for now, this simply deletes 'cache' and 'sesion' subfolders - see proper
# implementation in official doc.
# e.g. $ php admin/cli/purge_caches.php
#
# @example
#   make app-cc
#   # Or :
#   cwt/extensions/moodle_d4php/app/cc.sh
#

. cwt/bootstrap.sh

echo "Clearing Moodle caches..."

dirs_to_delete="$MOODLE_DATA_DIR/cache $MOODLE_DATA_DIR/session"

for dir_to_delete in $dirs_to_delete; do
  if [[ -n "$dir_to_delete" ]] && [[ ! -d "$dir_to_delete" ]]; then

    rm -rf "$dir_to_delete"

    if [[ $? -ne 0 ]]; then
      echo >&2
      echo "Error in $BASH_SOURCE line $LINENO: unable to create the required dir '$dir_to_delete'." >&2
      echo "-> Aborting (1)." >&2
      echo >&2
      exit 1
    fi
  fi
done

echo "Clearing Moodle caches : done."
