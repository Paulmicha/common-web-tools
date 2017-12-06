#!/bin/bash

##
# Implements u_hook_app 'bash' 'alias'.
#
# This file is dynamically included when the "hook" is triggered.
#

echo "($BASH_SOURCE loaded by u_hook_app $@)"

alias composer="composer --working-dir=$APP_DOCROOT"
alias drush="drush --root=$APP_DOCROOT"
