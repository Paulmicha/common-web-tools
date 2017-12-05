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
# Makes given absolute path relative to another, or $PROJECT_DOCROOT (default).
#
# @requires $PROJECT_DOCROOT global in calling scope.
#
# @param 1 String absolute path to convert to relative path (must start with '/').
# @param 2 [optional] String absolute reference path (must start with '/').
#   Defaults to PROJECT_DOCROOT value.
#
# @example
#   u_path_relative "$PROJECT_DOCROOT/yetetets/testtset/fdsf.fd"  # -> 'yetetets/testtset/fdsf.fd'
#   u_path_relative "/"                                           # -> '../../'
#   u_path_relative "/var/www/yetetets/testtset/fdsf.fd"          # -> '../../var/www/yetetets/testtset/fdsf.fd'
#
u_path_relative() {
  local target="$1"
  local source="$2"
  if [[ -z "$source" ]]; then
    source="$PROJECT_DOCROOT"
  fi

  local result=""
  local common_part="$source"

  while [[ "${target#$common_part}" == "${target}" ]]; do
    # no match, means that candidate common part is not correct
    # go up one level (reduce common part)
    common_part="$(dirname $common_part)"
    # and record that we went back, with correct / handling
    if [[ -z $result ]]; then
      result=".."
    else
      result="../$result"
    fi
  done

  if [[ $common_part == "/" ]]; then
    # special case for root (no common path)
    result="$result/"
  fi

  # since we now have identified the common part,
  # compute the non-common part
  forward_part="${target#$common_part}"

  # and now stick all parts together
  if [[ -n $result ]] && [[ -n $forward_part ]]; then
    result="$result$forward_part"
  elif [[ -n $forward_part ]]; then
    # extra slash removal
    result="${forward_part:1}"
  fi

  echo "$result"
}

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
