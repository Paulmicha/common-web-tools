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
# Gets all keys defined in given "keyed" space-separated string.
#
# @example
#   my_kss_str=''
#   eval "$(u_string_kss_write 'my_kss_str' 'key1' 'qsdljq sldkqj sdlkqjs dlkj')"
#   eval "$(u_string_kss_write 'my_kss_str' 'key2' 'B qsd')"
#   eval "$(u_string_kss_write 'my_kss_str' 'key3' 'C test')"
#   u_string_kss_get_keys "$my_kss_str" # outputs : 'key1 key2 key3'
#
u_string_kss_get_keys() {
  local p_sub_keyed_str="$1"

  local prefix_delimiter="$(u_string_common_val kss-prefix)"

  local sub_keyed_str_item=''
  local sub_keyed_str_key=''
  local sub_keyed_str_val=''

  local output=''

  for sub_keyed_str_item in $p_sub_keyed_str; do

    # Match last occurence of key from the end of the string.
    # See http://wiki.bash-hackers.org/syntax/pe#from_the_end
    sub_keyed_str_key="${sub_keyed_str_item%%$prefix_delimiter*}"

    output+=" $(u_string_trim "$sub_keyed_str_key")"
  done

  echo $(u_string_trim "$output")
}

##
# Reads value by key for "keyed" space-separated strings.
#
# @example
#   my_kss_str=''
#   eval "$(u_string_kss_write 'my_kss_str' 'key1' 'A This string/cannot #~ contain | {} [any] test ; quotes or asterisks (stars)')"
#   eval "$(u_string_kss_write 'my_kss_str' 'key2' 'B qsd')"
#   eval "$(u_string_kss_write 'my_kss_str' 'key3' 'C test')"
#   u_string_kss_read 'key2' "$my_kss_str" # outputs : 'B qsd'
#   u_string_kss_read 'key3' "$my_kss_str" # outputs : 'C test'
#
#   # Globals using the following syntax also use this technique :
#   global REMOTE_INSTANCES_CMDS "[append]='/path/to/remote/instance/docroot' [to]=PROJECT_DOCROOT"
#   u_string_kss_read 'PROJECT_DOCROOT' "$REMOTE_INSTANCES_CMDS"
#   # -> result : "/path/to/remote/instance/docroot"
#
u_string_kss_read() {
  local p_key="$1"
  local p_sub_keyed_str="$2"

  local prefix_delimiter="$(u_string_common_val kss-prefix)"
  local tmp_space_placeholder="$(u_string_common_val tmp-space-placeholder)"

  local sub_keyed_str_item=''
  local sub_keyed_str_key=''
  local sub_keyed_str_val=''

  local output=''

  for sub_keyed_str_item in $p_sub_keyed_str; do

    # Match last occurence of key from the end of the string.
    # See http://wiki.bash-hackers.org/syntax/pe#from_the_end
    sub_keyed_str_key="${sub_keyed_str_item%%$prefix_delimiter*}"

    if [[ "$sub_keyed_str_key" == "$p_key" ]]; then
      # Match 1st occurence of key from the beginning of the string.
      # See http://wiki.bash-hackers.org/syntax/pe#from_the_beginning
      sub_keyed_str_val="${sub_keyed_str_item#*$prefix_delimiter}"
<<<<<<< HEAD
      output+="$(u_str_replace "$tmp_space_placeholder" ' ' "$sub_keyed_str_val") "
=======

      # Decode the value that was base64-encoded to workaround spaces.
      # @see u_string_kss_write()
      output+=" $(printf "%s" "$sub_keyed_str_val" | base64 --decode) "
>>>>>>> 3b26e24... Fix u_string_kss_read().
    fi
  done

  echo $(u_string_trim "$output")
}

##
# Adds a single value (string, no quotes) to a keyed space-separated string.
#
# @requires String var whose name is $1 in calling scope.
#
# @param 1 String the variable name that will store the formattedkey/value pair.
# @param 2 String the key.
# @param 2 String the value. WARNING : cannot contain * or unescaped $ chars.
#
# @example
#   my_kss_str=''
#   eval "$(u_string_kss_write 'my_kss_str' 'key1' 'This string/cannot #~ contain | {} [any] test ; quotes or asterisks (stars))"
#
u_string_kss_write() {
  local p_var="$1"
  local p_key="$2"
  local p_val="$3"

  local prefix_delimiter="$(u_string_common_val kss-prefix)"
  local tmp_space_placeholder="$(u_string_common_val tmp-space-placeholder)"
  local val="${p_val//' '/"$tmp_space_placeholder"}"

  echo "$p_var+=\" ${p_key}${prefix_delimiter}${val} \""
}

##
# [debug] Prints all data defined in given "keyed" space-separated string.
#
# @example
#   u_string_kss_debug 'MY_VAR_NAME'
#
u_string_kss_debug() {
  local p_var_name="$1"

  eval "local sub_keyed_str=\"\$$p_var_name\""

  local keys="$(u_string_kss_get_keys "$sub_keyed_str")"
  local key
  local val

  echo
  echo "'$p_var_name' has the following keys : $keys"
  echo

  for key in $keys; do
    val="$(u_string_kss_read "$key" "$sub_keyed_str")"
    if [[ -n "$val" ]]; then
      echo "  ${p_var_name}.${key} = $val"
    fi
  done
  echo
}

##
# Centralizes arbitrary unique values (e.g. for delimiters, placeholders, etc).
#
# @example
#   unique_delimiter_str="$(u_string_common_val kss-prefix)"
#   echo "$unique_delimiter_str"
#
u_string_common_val() {
  case "$1" in
    kss-prefix) echo ":cwt-kssp:" ;;
    tmp-space-placeholder) echo ":cwt-tsph:" ;;
  esac
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
