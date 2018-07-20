#!/usr/bin/env bash

##
# String-related utility functions.
#
# This file is sourced during core CWT bootstrap.
# @see cwt/bootstrap.sh
#
# Convention : functions names are all prefixed by "u" (for "utility").
#

##
# Sanitizes a string to be used as a variable name (for 'eval').
#
# This function is a "preset" of the more generic string sanitizing utility.
# @see u_str_sanitize()
#
# @param 1 String : variable name to be sanitized.
# @param 2 String : name of the variable in calling scope which holds the
#   variable name to be sanitized (acronym : notvicswhtvntbs).
#
# @see https://stackoverflow.com/a/41059855 (why use 'eval' in the first place).
#
# @example
#   # Typical use case : see u_str_split1().
#   local p_var_name="$1"
#   u_str_sanitize_var_name "$p_var_name" 'p_var_name'
#   echo "$p_var_name" # <- Prints sanitized variable name.
#
u_str_sanitize_var_name() {
  local p_input="$1"
  local p_notvicswhtvntbs="$2"

  # The variable p_notvicswhtvntbs must not collide in calling scope. Hopefully
  # the acronym used here is enough to make it sufficiently unlikely.
  printf -v "$p_notvicswhtvntbs" '%s' "${p_notvicswhtvntbs//[^a-zA-Z0-9_]/_}"

  u_str_sanitize "$p_input" '_' "$p_notvicswhtvntbs" '[^a-zA-Z0-9_]'
}

##
# Sanitizes strings (basic search/replace using regex).
#
# @param 1 String : the value to sanitize.
# @param 2 [optional] String : with what to replace filtered out characters.
#   Defaults to : '-'.
# @param 3 [optional] String : the variable name in calling scope which will
#   hold the result for performance reasons (to avoid using a subshell).
#   Defaults to : 'sanitized_str'.
# @param 4 [optional] String : characters to filter (regex). Defaults to :
#   '[^a-zA-Z0-9_\-\.]'
#
# NB : for performance reasons (to avoid using a subshell), this function
# writes its result to a variable subject to collision in calling scope.
# The default variable name is overridable : see arg 3.
#
# @var [default(3)] sanitized_str
#
# @see cwt/test/cwt/utilities.test.sh
#
# @example
#   u_str_sanitize "a b c d"
#   echo "$sanitized_str" # <- Prints 'a-b-c-d'
#   u_str_sanitize "a b c d" '_'
#   echo "$sanitized_str" # <- Prints 'a_b_c_d'
#
u_str_sanitize() {
  local p_ussvfhnc_str="$1"
  local p_ussvfhnc_replace="$2"
  local p_ussvfhnc_var_name="$3"
  local p_ussvfhnc_filter="$4"

  if [[ -z "$p_ussvfhnc_filter" ]]; then
    p_ussvfhnc_filter='[^a-zA-Z0-9_\-\.]'
  fi

  # Allows empty strings.
  if [[ $# -lt 2 ]] && [[ -z "$p_ussvfhnc_replace" ]]; then
    p_ussvfhnc_replace='-'
  fi

  if [[ -z "$p_ussvfhnc_var_name" ]]; then
    p_ussvfhnc_var_name='sanitized_str'
  fi

  # ${!p_ussvfhnc_var_name}="${p_ussvfhnc_str//$p_ussvfhnc_filter/$p_ussvfhnc_replace}"
  printf -v "$p_ussvfhnc_var_name" '%s' "${p_ussvfhnc_str//$p_ussvfhnc_filter/$p_ussvfhnc_replace}"
}

##
# Gets all unique unordered combinations of given string values.
#
# See https://codereview.stackexchange.com/questions/7001/generating-all-combinations-of-an-array
# + https://stackoverflow.com/a/23653825
#
# NB : for performance reasons (to avoid using a subshell), this function
# writes its result to a variable subject to collision in calling scope.
#
# @var str_subsequences
#
# @param 1 String : space-separated values.
# @param 2 [optional] String : concatenation separator. Defaults to '' (empty).
# @param 3 [optional] String : separator between items. Defaults to space.
#
# @example
#   u_str_subsequences "a b c d"
#   echo "$str_subsequences" # a ab abc abcd abd ac acd ad b bc bcd bd c cd d
#
#   # Custom concatenation character.
#   u_str_subsequences "a b c d" '.'
#   for i in $str_subsequences; do
#     echo "$i" # Ex: a.b.c.d
#   done
#
u_str_subsequences() {
  local p_values="$1"
  local p_concatenation="$2"
  local p_separator="$3"

  if [[ -z "$p_separator" ]]; then
    p_separator=' '
  fi

  str_subsequences=''

  _u_str_subsequences_inner_recursion() {
    local p_prefix="$1"
    local p_inner_values="$2"

    local i
    local concat="$p_concatenation"

    if [[ -z "$p_prefix" ]]; then
      concat=""
    fi

    for i in $p_inner_values; do
      str_subsequences+="${p_prefix}${concat}${i}${p_separator}"
      _u_str_subsequences_inner_recursion "${p_prefix}${concat}${i}" "${p_inner_values#*$i}"
    done
  }

  _u_str_subsequences_inner_recursion '' "$p_values"

  unset -f _u_str_subsequences_inner_recursion
}

##
# Transforms an existing variable named $lowercase in calling scope to lowercase.
#
# @requires Bash 4+ (MacOS needs manual update).
# See https://stackoverflow.com/questions/2264428/converting-string-to-lower-case-in-bash
#
# @example
#   lowercase=''
#   u_str_lowercase 'MY_STRING'
#   echo "$lowercase" # Outputs 'my_string'
#
#   # Using custom variable name :
#   my_custom_var_name=''
#   u_str_lowercase 'MY_STRING' my_custom_var_name
#   echo "$my_custom_var_name" # Outputs 'my_string'
#
u_str_lowercase() {
  local p_input="$1"
  local p_str_lowercase_var_name="$2"

  if [[ -z "$p_str_lowercase_var_name" ]]; then
    p_str_lowercase_var_name='lowercase'
  fi

  printf -v "$p_str_lowercase_var_name" '%s' "${p_input,,}"
}

##
# Transforms an existing variable named $uppercase in calling scope to uppercase.
#
# @requires Bash 4+ (MacOS needs manual update).
# See https://stackoverflow.com/questions/2264428/converting-string-to-lower-case-in-bash
#
# @example
#   uppercase=''
#   u_str_uppercase 'my_string'
#   echo "$uppercase" # Outputs 'MY_STRING'
#
#   # Using custom variable name :
#   my_custom_var_name=''
#   u_str_uppercase 'my_string' my_custom_var_name
#   echo "$my_custom_var_name" # Outputs 'MY_STRING'
#
u_str_uppercase() {
  local p_input="$1"
  local p_str_uppercase_var_name="$2"

  if [[ -z "$p_str_uppercase_var_name" ]]; then
    p_str_uppercase_var_name='uppercase'
  fi

  printf -v "$p_str_uppercase_var_name" '%s' "${p_input^^}"
}

##
# Escapes all slashes for use in 'sed' calls.
#
# TODO [opti] Rewrite without subshell.
#
# @see u_fs_change_line()
#
# @example
#   my_var=$(u_str_sed_escape "A string with commas, and dots... !")
#   echo "$my_var" # Outputs "A string with commas\, and dots\.\.\. !"
#
u_str_sed_escape() {
  local p_str="$1"

  p_str="${p_str//,/\\,}"
  p_str="${p_str//\./\\\.}"
  p_str="${p_str//\*/\\\*}"
  p_str="${p_str//\//\\\/}"

  echo "$p_str"
}

##
# Appends a given value to a string only once.
#
# TODO [opti] Rewrite without subshell.
#
# @param 1 String : the value to append.
# @param 2 String : to which str to append that value to.
#
# @example
#   str='Foo bar'
#   str="$(u_str_append_once '--test A' "$str")" # str='Foo bar--test A'
#   str="$(u_str_append_once '--test A' "$str")" # (unchanged)
#   str="$(u_str_append_once '--test B' "$str")" # str='Foo bar--test A--test B'
#
u_str_append_once() {
  local p_needle="$1"
  local p_haystack="$2"

  if [[ -z "$p_haystack" ]]; then
    echo -n "$p_needle"
    return
  fi

  if [[ "$p_haystack" != *"$p_needle"* ]]; then
    echo -n "${p_haystack}${p_needle}"
  else
    echo -n "${p_haystack}"
  fi
}

##
# Splits a string given a 1-character long separator.
#
# @param 1 The variable name that will contain the array of substrings (in calling scope).
# @param 2 String to split.
# @param 3 String : separator that must be 1 character long.
#
# @example
#   u_str_split1 'MY_VAR_NAME' "the,string" ','
#   for substr in "${MY_VAR_NAME[@]}"; do
#     echo "$substr"
#   done
#
u_str_split1() {
  local p_str_split1_var_name="$1"
  local p_str="$2"
  local p_sep="$3"

  u_str_sanitize_var_name "$p_str_split1_var_name" 'p_str_split1_var_name'

  # See https://stackoverflow.com/a/41059855
  eval "${p_str_split1_var_name}=()"

  # See https://stackoverflow.com/a/45201229 (#7)
  while read -rd"$p_sep"; do
    eval "${p_str_split1_var_name}+=(\"$REPLY\")"
  done <<<"${p_str}${p_sep}"
}

##
# Generates a random string.
#
# TODO [evol] optimize this.
#
# @param 1 [optional] Integer : string length - default : 16.
#
# @example
#   RANDOM_STR=$(u_str_random)
#
u_str_random() {
  local l="16"

  if [[ -n "${1}" ]]; then
    l="${1}"
  fi

  < /dev/urandom tr -dc A-Za-z0-9 | head -c$l; echo
}

##
# Generates a slug from string.
#
# Accepts an additional parameter to specify the replacement character.
# See https://gist.github.com/oneohthree/f528c7ae1e701ad990e6
#
# @param 1 String : the string to convert.
# @param 2 [optional] String : the replacement character.
#
# @example
#   SLUG=$(u_str_slug "A string with non-standard characters and accents. éàù!îôï. Test out!")
#   echo "$SLUG" # Result : "a-string-with-non-standard-characters-and-accents-eau-ioi-test-out"
#
# @example with different custom separator :
#   # WARNING : regex special characters need escaping.
#   SLUG_DOT=$(u_str_slug "second test .. 456.2" '\.')
#   echo "$SLUG" # Result : "second.test.456.2"
#
u_str_slug() {
  local p_str="$1"
  local p_sep="$2"

  local sep='-'
  if [[ -n "$p_sep" ]]; then
    sep="$p_sep"
  fi

  echo "$p_str" \
    | iconv -t ascii//TRANSLIT \
    | sed -r s/[~\^]+//g \
    | sed -r s/[^a-zA-Z0-9]+/"$sep"/g \
    | sed -r s/^"$sep"+\|"$sep"+$//g \
    | tr A-Z a-z
}

##
# Generates a slug from string - variant using underscores instead of dashes.
#
# @see u_str_slug()
#
u_str_slug_u() {
  echo "${1}" \
    | iconv -t ascii//TRANSLIT \
    | sed -r s/[~\^]+//g \
    | sed -r s/[^a-zA-Z0-9]+/_/g \
    | sed -r s/^_+\|_+$//g \
    | tr A-Z a-z
}

##
# Removes trailing white space.
#
# See https://stackoverflow.com/questions/369758/how-to-trim-whitespace-from-a-bash-variable
#
# @param 1 String : the string to trim.
#
# @example
#   str_trimmed=$(u_str_trim " testing space trim ")
#   echo "str_trimmed = '$str_trimmed'"
#
u_str_trim() {
  echo "$(echo -e "$1" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
}
