#!/bin/bash

##
# String-related utility functions.
#
# This script is dynamically loaded.
# @see cwt/bash_utils.sh
#
# Convention : functions names are all prefixed by "u" (for "utility").
#

##
# Splits a string given a 1-character long separator.
#
# @param 1 The variable name that will contain the array of substrings (in calling scope).
# @param 2 String to split.
# @param 3 String : separator that must be 1 character long.
#
# @example
#   u_str_split1 MY_VAR_NAME 'the,string' ','
#   for substr in "${MY_VAR_NAME[@]}"; do
#     echo "$substr"
#   done
#
u_str_split1() {
  local p_var_name="$1"
  local p_str="$2"
  local p_sep="$3"

  # See https://stackoverflow.com/a/41059855
  eval "${p_var_name}=()"

  # See https://stackoverflow.com/a/45201229 (#7)
  while read -rd"$p_sep"; do
    eval "${p_var_name}+=(\"$REPLY\")"
  done <<<"${p_str}${p_sep}"
}

##
# Generates a random string.
#
# @param 1 [optional] Integer : string length - default : 16.
#
# @example
#   RANDOM_STR=$(u_random_str)
#
u_random_str() {
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
#   SLUG=$(u_slugify "A string with non-standard characters and accents. éàù!îôï. Test out!")
#   echo "$SLUG" # Result : "a-string-with-non-standard-characters-and-accents-eau-ioi-test-out"
#
# @example with different custom separator :
#   # WARNING : regex special characters need escaping.
#   SLUG_DOT=$(u_slugify "second test .. 456.2" '\.')
#   echo "$SLUG" # Result : "second.test.456.2"
#
u_slugify() {
  local p_str="$1"
  local p_sep="$2"

  local sep='-'
  if [[ -n "$p_sep" ]]; then
    sep="$p_sep"
  fi

  echo "$p_str" | iconv -t ascii//TRANSLIT | sed -r s/[~\^]+//g | sed -r s/[^a-zA-Z0-9]+/"$sep"/g | sed -r s/^"$sep"+\|"$sep"+$//g | tr A-Z a-z
}

##
# Generates a slug from string - variant using underscores instead of dashes.
#
# @see u_slugify()
#
u_slugify_u() {
  echo "${1}" | iconv -t ascii//TRANSLIT | sed -r s/[~\^]+//g | sed -r s/[^a-zA-Z0-9]+/_/g | sed -r s/^_+\|_+$//g | tr A-Z a-z
}

##
# Prompts for a value in terminal.
#
# @param 1 String : the question.
#
# @example
#   input_git_user_name=$(u_prompt "please enter your Git user name : ")
#   echo "You entered : '$input_git_user_name'"
#
u_prompt() {
  local p_question="$1"
  local input=''
  read -p "$p_question" input
  echo "$input"
}
