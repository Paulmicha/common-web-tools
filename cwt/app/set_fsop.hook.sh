#!/usr/bin/env bash

##
# Implements hook -a 'set_fsop' -s 'app stack'.
#
# This file is dynamically included when the "hook" is triggered.
#

if [[ -n "$PROTECTED_FILES" ]]; then
  for protected_file in $PROTECTED_FILES; do
    if [[ -f "$protected_file" ]]; then
      chmod -wx "$protected_file"
    fi
  done
fi

if [[ -n "$WRITEABLE_FILES" ]]; then
  for writeable_file in $WRITEABLE_FILES; do
    if [[ -d "$writeable_file" ]]; then
      chmod +w "$writeable_file"
    fi
  done
fi

if [[ -n "$WRITEABLE_DIRS" ]]; then
  for writeable_dir in $WRITEABLE_DIRS; do
    if [[ -d "$writeable_dir" ]]; then
      chmod +w "$writeable_dir" -R
    fi
  done
fi