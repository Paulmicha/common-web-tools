#!/usr/bin/env bash

##
# Implements hook -s 'app instance' -a 'ensure_dirs_exist'
#
# @see u_instance_init()
#

if [ -n "$CWT_DB_DUMPS_DIR" ] && [ ! -d "$CWT_DB_DUMPS_DIR" ]; then
  echo "Creating missing dir '$CWT_DB_DUMPS_DIR'."
  mkdir -p "$CWT_DB_DUMPS_DIR"
fi
