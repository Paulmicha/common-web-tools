#!/bin/bash

##
# Implements u_hook_app_call 'apply' 'ownership_and_perms' '' 'stack'.
#
# This file is dynamically included when the "hook" is triggered.
#

if [[ -d "$PROJECT_DOCROOT/cwt" ]]; then
  chmod u+x "$PROJECT_DOCROOT/cwt" -R
fi

if [[ -d "$PROJECT_DOCROOT/scripts" ]]; then
  chmod u+x "$PROJECT_DOCROOT/scripts" -R
fi
