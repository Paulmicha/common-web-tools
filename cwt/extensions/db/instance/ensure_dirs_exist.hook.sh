#!/usr/bin/env bash

##
# Implements hook -s 'app instance' -a 'ensure_dirs_exist'
#
# @see u_instance_init()
#

if [ -n "$CWT_DB_DUMPS_BASE_PATH" ] && [ ! -d "$CWT_DB_DUMPS_BASE_PATH" ]; then
  echo "Creating missing dir ${CWT_DB_DUMPS_BASE_PATH}."
  mkdir -p "$CWT_DB_DUMPS_BASE_PATH"
fi
