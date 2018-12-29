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

##
# Quickly sorts an array.
#
# NB : for performance reasons (to avoid using a subshell), this function
# writes its result to a variable subject to collision in calling scope.
#
# @var sorted_arr
#
# See https://stackoverflow.com/a/30576368
#
# @example
#   array=(a c b f 3 5)
#   u_array_qsort "${array[@]}"
#   # Check result :
#   declare -p sorted_arr
#   # -> output :
#   #   declare -a sorted_arr='([0]="3" [1]="5" [2]="a" [3]="b" [4]="c" [5]="f")'
#
u_array_qsort() {
  (($#==0)) && return 0
  local stack=( 0 $(($#-1)) ) beg end i pivot smaller larger
  sorted_arr=("$@")

  while ((${#stack[@]})); do
    beg=${stack[0]}
    end=${stack[1]}
    stack=( "${stack[@]:2}" )
    smaller=() larger=()
    pivot=${sorted_arr[beg]}

    for ((i=beg+1;i<=end;++i)); do
      if [[ "${sorted_arr[i]}" < "$pivot" ]]; then
        smaller+=( "${sorted_arr[i]}" )
      else
        larger+=( "${sorted_arr[i]}" )
      fi
    done

    sorted_arr=( "${sorted_arr[@]:0:beg}" "${smaller[@]}" "$pivot" "${larger[@]}" "${sorted_arr[@]:end+1}" )

    if ((${#smaller[@]}>=2)); then
      stack+=( "$beg" "$((beg+${#smaller[@]}-1))" )
    fi

    if ((${#larger[@]}>=2)); then
      stack+=( "$((end-${#larger[@]}+1))" "$end" )
    fi
  done
}

##
# Prints array (debug utility).
#
# See https://unix.stackexchange.com/a/366655
#
# @example (associative array)
#   declare -A a=([a]=123 [b]="foo bar" [c]="(blah)")
#   u_array_print a
#   # -> outputs :
#   #   a=123
#   #   b=foo bar
#   #   c=(blah)
#
# @example (normal array)
#   b=(abba acdc)
#   u_array_print b
#   # -> outputs :
#   #   0=abba
#   #   1=acdc
#
u_array_print() {
  declare -n __p="$1"
  for k in "${!__p[@]}"; do
    printf "%s=%s\n" "$k" "${__p[$k]}"
  done
}
