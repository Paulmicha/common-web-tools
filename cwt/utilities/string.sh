#!/usr/bin/env bash

##
# String-related utility functions.
#
# This script is dynamically loaded.
# @see cwt/bootstrap.sh
#
# Convention : functions names are all prefixed by "u" (for "utility").
#

##
# Escapes all slashes for use in 'sed' calls.
#
# @see u_str_change_line()
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
# Replaces an entire line in given file.
#
# See https://stackoverflow.com/questions/11245144/replace-whole-line-containing-a-string-using-sed
#
# @example
#   u_str_change_line "The existing line matching pattern" "The replacement text" path/to/file.ext
#
u_str_change_line() {
  local p_existing_line_match="$1"
  local p_replacement="$2"
  local p_file="$3"

  local new=$(u_str_sed_escape "${p_replacement}")

  sed "/$p_existing_line_match/c $new" -i "$p_file"
}


##
# Appends a given value to a string only once.
#
# @param 1 String : the value to append.
# @param 2 String : to which str to append that value to.
#
# @example
#   str='Foo bar'
#   str="$(u_string_append_once '--test A' "$str")" # str='Foo bar--test A'
#   str="$(u_string_append_once '--test A' "$str")" # (unchanged)
#   str="$(u_string_append_once '--test B' "$str")" # str='Foo bar--test A--test B'
#
u_string_append_once() {
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
# Replaces all occurences of a substring by another in given string.
#
# @example
#   # Yields 'qsdqsdazemlkjdfoiuzrekh'
#   echo "$(u_str_replace ' ' '' 'qsdqsd aze mlkj dfoiu zrekh')"
#
u_str_replace() {
  local p_search="$1"
  local p_replace="$2"
  local p_haystack="$3"

  echo "${p_haystack//$p_search/"$p_replace"}"
}

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

##
# Removes trailing white space.
#
# See https://stackoverflow.com/questions/369758/how-to-trim-whitespace-from-a-bash-variable
#
# @param 1 String : the string to trim.
#
# @example
#   str_trimmed=$(u_string_trim " testing space trim ")
#   echo "str_trimmed = '$str_trimmed'"
#
u_string_trim() {
  echo "$(echo -e "$1" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
}
