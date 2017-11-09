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
# Quicksorts positional arguments
#
# Return is in array qsort_ret.
# See https://stackoverflow.com/a/30576368
#
# @example
#   array=(a c b f 3 5)
#   u_array_sort "${array[@]}"
#   # To debug result :
#   declare -p qsort_ret
#
u_array_sort() {
  (($#==0)) && return 0
  local stack=( 0 $(($#-1)) ) beg end i pivot smaller larger
  qsort_ret=("$@")
  while ((${#stack[@]})); do
    beg=${stack[0]}
    end=${stack[1]}
    stack=( "${stack[@]:2}" )
    smaller=() larger=()
    pivot=${qsort_ret[beg]}
    for ((i=beg+1;i<=end;++i)); do
      if [[ "${qsort_ret[i]}" < "$pivot" ]]; then
        smaller+=( "${qsort_ret[i]}" )
      else
        larger+=( "${qsort_ret[i]}" )
      fi
    done
    qsort_ret=( "${qsort_ret[@]:0:beg}" "${smaller[@]}" "$pivot" "${larger[@]}" "${qsort_ret[@]:end+1}" )
    if ((${#smaller[@]}>=2)); then stack+=( "$beg" "$((beg+${#smaller[@]}-1))" ); fi
    if ((${#larger[@]}>=2)); then stack+=( "$((end-${#larger[@]}+1))" "$end" ); fi
  done
}
