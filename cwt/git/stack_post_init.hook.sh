#!/bin/bash

##
# Implements u_hook_call 'stack' 'init' 'post'.
#
# @requires the following variables in calling scope (main shell) :
# @see cwt/env/current/vars.sh
#
# TODO document this.
# This file is dynamically included when the "hook" is triggered.
#

# Only clone an app repo if current project is not 'monolithic'.
if [[ "$CWT_MODE" == 'separate' ]]; then
  if [[ (-n "$APP_GIT_ORIGIN") && (-n "$APP_GIT_DIR") ]]; then

    # Ensure idempotence (only attempt to clone if it's not already done).
    if [[ ! -d "$APP_GIT_DIR/.git" ]]; then
      git clone "$APP_GIT_ORIGIN" "$APP_GIT_DIR"
    fi

    # Apply git config locally from APP_GIT_DIR (may be different than
    # APP_DOCROOT which is a typical entry point for web server softwares).
    . cwt/git/apply_config.sh
  fi
fi
