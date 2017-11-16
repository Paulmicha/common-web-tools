#!/bin/bash

##
# File-related utility functions.
#
# This script is dynamically loaded.
# @see cwt/bash_utils.sh
#
# Convention : functions names are all prefixed by "u" (for "utility").
#

##
# Prints bash script file absolute path (from where this function is called).
#
# @param 1 String : the bash script file - use ${BASH_SOURCE[0]} for the current
#   (calling) file.
#
# @example
#   FILE_ABS_PATH=$(u_get_script_path ${BASH_SOURCE[0]})
#
u_get_script_path() {
  echo $(cd "$(dirname "$1")" && pwd)/$(basename "$1")
}
