#!/bin/bash

##
# Array-related utility functions.
#
# This script is dynamically loaded.
# @see cwt/bash_utils.sh
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
# Simulates nested associative arrays in bash (1-level).
#
# See https://stackoverflow.com/a/25221316
#
# @example to write into associative array :
#   arr=(a aa aaa)
#   declare -A base_arr
#   u_nest_array base_arr 'key' "${a[@]}"
#
# @example to read :
#   echo "${base_arr[key|1]}"
function u_nest_array {
  local var=$1 base_key=$2 values=("${@:3}")
  for i in "${!values[@]}"; do
    eval "$1[\$base_key|$i]=\${values[i]}"
  done
}
