#!/usr/bin/env bash

##
# Array-related utility functions.
#
# This file is sourced during core CWT bootstrap.
# @see cwt/bootstrap.sh
#
# Convention : functions names are all prefixed by "u" (for "utility").
#

##
# Checks if an array contains an item.
#
# @param 1 String needle.
# @param 2 Array haystack.
#
# @example
#   declare -a my_array=("test1" "test2" "test3");
#   if u_in_array 'test1' my_array; then
#     echo "Ok, 'test1' found in my_array"
#   else
#     echo "'test1' NOT found in my_array"
#   fi
#
u_in_array() {
  local needle="${1}"
  local haystack=${2}[@]
  local i

  for i in ${!haystack}; do
    if [[ "$i" == "$needle" ]]; then
      return 0
    fi
  done

  return 1
}

##
# Adds item in array only once (idempotent).
#
# @param 1 String needle.
# @param 2 String the Array variable name (haystack).
#
# @example
#   declare -a my_array=("test1" "test2" "test3");
#   u_array_add_once "test1" my_array
#   u_array_add_once "test4" my_array
#   u_array_add_once "test2" my_array
#   # To debug result :
#   declare -p my_array
#
u_array_add_once() {
  local needle="${1}"
  local haystack_var_name="${2}"

  if ! u_in_array $needle $haystack_var_name; then
    eval "$haystack_var_name+=($needle)"
  fi
}
