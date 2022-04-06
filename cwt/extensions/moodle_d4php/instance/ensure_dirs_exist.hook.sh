#!/usr/bin/env bash

##
# Implements hook -s 'app instance' -a 'ensure_dirs_exist'
#
# @see u_instance_init()
#

required_dirs="$MOODLE_DATA_DIR $MOODLE_PHPUNITDATA_DIR $MOODLE_BEHATDATA_DIR $MOODLE_BEHATFAILDUMPS_DIR"

for required_dir in $required_dirs; do
  if [[ -n "$required_dir" ]] && [[ ! -d "$required_dir" ]]; then

    echo "Creating missing dir ${required_dir}"
    mkdir -p "$required_dir"

    if [[ $? -ne 0 ]]; then
      echo >&2
      echo "Error in $BASH_SOURCE line $LINENO: unable to create the required dir '$required_dir'." >&2
      echo "-> Aborting (1)." >&2
      echo >&2
      exit 1
    fi
  fi
done
