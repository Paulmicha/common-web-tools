#!/bin/bash

##
# Bash scripts utilities.
#
# This will dynamically source all files found inside cwt/utilities folder.
# They should contain only function declarations, using the following
# Convention : fonctions names are all prefixed by "u" (for "utility").
#
# Load from project root dir :
# $ . cwt/bash_utils.sh
#

for file in $( find cwt/utilities/* -type f -print0 | xargs -0 ); do
  . $file
done
