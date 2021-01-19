#!/usr/bin/env bash

##
# Deletes any traces of previous init in current project instance.
#
# TODO introduce hook for letting extensions clean up their own generated files.
#
# @example
#   make uninit
#   # Or :
#   cwt/instance/uninit.sh
#

cwt_instance_uninit_purge_list=".env
scripts/cwt/local/global.vars.sh
scripts/cwt/local/default.mk
docker-compose.yml
docker-compose.override.yml"

for f in $cwt_instance_uninit_purge_list; do
  if [[ -f "$f" ]]; then
    rm "$f"
    if [[ $? -ne 0 ]]; then
      echo >&2
      echo "Error in $BASH_SOURCE line $LINENO: unable to delete file '$f'." >&2
      echo "-> Aborting (1)." >&2
      echo >&2
      exit 1
    else
      echo "Successfully removed file '$f'."
    fi
  fi
done
