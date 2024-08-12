#!/usr/bin/env bash

##
# Deletes any traces of previous init in current project instance.
#
# The following hook is provided for letting extensions clean up their own
# generated files and/or alter the purge_list :
#
# $ make hook-debug s:instance a:uninit v:PROVISION_USING HOST_TYPE INSTANCE_TYPE
#
# These implementations may optionally alter entries to the following var in
# calling scope :
#
# @var purge_list
#
# @example
#   make uninit
#   # Or :
#   cwt/instance/uninit.sh
#

. cwt/bootstrap.sh

purge_list=()

# Manual cleanup of CWT "core" global env vars.
purge_list+=('.env')
purge_list+=('scripts/cwt/local/global.vars.sh')
purge_list+=('scripts/cwt/local/default.mk')
purge_list+=('scripts/cwt/local/make_args_check.sh')

# Let extensions clean up their own generated files and/or alter the purge_list.
hook -s 'instance' -a 'uninit' -v 'PROVISION_USING HOST_TYPE INSTANCE_TYPE'

# Process the purge_list.
for entry in "${purge_list[@]}"; do
  if [[ -z "$entry" ]]; then
    continue
  fi

  if [[ -d "$entry" ]]; then
    echo
    echo "Notice : entire folders are not purged in 'uninit' (only files)."
    echo "  -> skipped dir : $entry"
    echo

    continue
  fi

  if [[ -f "$entry" ]]; then
    rm "$entry"

    if [[ $? -ne 0 ]]; then
      echo >&2
      echo "Error in $BASH_SOURCE line $LINENO: unable to delete file '$entry'." >&2
      echo "-> Aborting (1)." >&2
      echo >&2
      exit 1
    else
      echo "Successfully removed file '$entry'."
    fi
  fi
done

# Clear all CWT cache entries.
. cwt/cache/clear.sh
