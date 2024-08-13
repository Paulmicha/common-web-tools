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
# Converts tokens from given global (or any variable containing any token).
#
# This is used for things like file names patterns, as in the "db" extension :
# {{ %Y-%m-%d.%H-%M-%S }}_local-{{ DB_ID }}.{{ USER }}.{{ DUMP_FILE_EXTENSION }}
#
# Tokens can be any variable name available in calling scope, date formatters,
# or anything that can be evaled.
#
# By convention, this function writes its result to a variable named by default
# after the global name transformed to lowercase.
#
# @param 1 String : input var name.
# @param 2 [optional] String : output var name.
#   Defaults to param 1 in lowercase.
# @param 3 [optional] Int : recursive calls counter. Because there are tokens
#   that may point to values that also contain tokens, this function calls
#   itself at the end to traverse all the tokens. But we need to be able to
#   break out of the recursion if a token cannot get replaced due to missing
#   value.
#
# @example
#   # Use the default naming convention :
#   DUMP_FILE_EXTENSION='sql'
#   u_str_convert_tokens CWT_DB_DUMPS_LOCAL_PATTERN
#   echo "cwt_db_dumps_local_pattern = '$cwt_db_dumps_local_pattern'"
#
#   # Provide a specific var name for reading the result :
#   u_str_convert_tokens CWT_DB_DUMPS_LOCAL_PATTERN 'my_var_name'
#   echo "my_var_name = '$my_var_name'"
#
u_str_convert_tokens() {
  local p_input_var_name="$1"
  local p_output_var_name="$2"
  local p_circuit_breaker=0

  if [[ -z "$p_input_var_name" ]]; then
    echo >&2
    echo "Error in u_str_convert_tokens() - $BASH_SOURCE line $LINENO: param 1 (p_input_var_name) is required." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    return 1
  fi

  if [[ -z "$p_output_var_name" ]]; then
    u_str_lowercase "$p_input_var_name" 'p_output_var_name'
  fi

  if [[ $3 -gt $p_circuit_breaker ]]; then
    p_circuit_breaker=$3
  fi

  local tokens_replaced="${!p_input_var_name}"
  local regex="\{\{[[:space:]]*([^[:space:]]+)[[:space:]]*\}\}"
  local regex_loop_str="$tokens_replaced"
  local token=''
  local match=''
  local val=''
  local token_var_name_check=''

  while [[ "$regex_loop_str" =~ $regex ]]; do
    token="${BASH_REMATCH[0]}"
    match="${BASH_REMATCH[1]}"

    # For the while loop to get all tokens, it needs to be gradually pruned.
    regex_loop_str="${regex_loop_str#*$token}"

    val=''
    token_var_name_check=''

    # Anything with a '%' character is considered a date formatter.
    case "$match" in *'%'*)
      val="$(date +"$match")"

      # Debug.
      # echo "token = '$token'"
      # echo "  val = '$val'"

      tokens_replaced="${tokens_replaced//$token/$val}"
      continue
    esac

    u_str_sanitize_var_name "$match" 'token_var_name_check'

    if [[ "$token_var_name_check" == "$match" && -v $match ]]; then
      val="${!match}"
    fi

    # Debug.
    # echo "val.1 = '$val'"

    # If the attempt to convert to a variable name produces an empty string, we
    # move on to the eval (in a subshell).
    if [[ -z "$val" ]]; then
      # Debug.
      # echo "val=\"\$($match)\""

      eval "val=\"\$($match)\""
    fi

    # Debug.
    # echo "val.2 = '$val'"

    # TODO is it ok to require that all tokens not be empty ?
    if [[ -n "$val" ]]; then
      tokens_replaced="${tokens_replaced//$token/$val}"
    fi
  done

  # There are tokens that may point to values that also contain tokens.
  case "$tokens_replaced" in *'{{ '*)
    # Up to 9 recursions is probably more than enough.
    if [[ $p_circuit_breaker -lt 10 ]]; then
      p_circuit_breaker+=1
      u_str_convert_tokens "$p_input_var_name" "$p_output_var_name" $p_circuit_breaker
    else
      echo >&2
      echo "Error : breaking out of u_str_convert_tokens() recursion." >&2
      echo "This likely means that at least one token value is empty in :" >&2
      echo "  $tokens_replaced" >&2
      echo >&2
      exit 2
    fi
  esac

  # Write result to var in calling scope.
  printf -v "$p_output_var_name" '%s' "$tokens_replaced"
}

##
# Single quotes escaping trick.
#
# The escaping is done in a way compatible with the way shell concatenates
# input strings.
#
# I.e. :
#   'test with 'single' quotes.'
# becomes :
#   'test with '"'"'single'"'"' quotes.'
#
# @link https://stackoverflow.com/a/1250279
#
# @see cwt/escape.sh
# @see cwt/make/call_wrap.make.sh
#
u_str_escape_single_quotes() {
  local p_arg="$1"
  local p_var_name="$2"

  if [[ -z "$p_var_name" ]]; then
    p_var_name='escaped_arg'
  fi

  escaped_arg="$p_arg"

  case "$p_arg" in
    *' '*|*'$'*|*'#'*|*'['*|*']'*|*'*|*'*|*'&'*|*'*'*|*'"'*|*"'"*|*'='*)
      p_arg="${p_arg//\'/"'\"'\"'"}"
      escaped_arg="'${p_arg}'"
      ;;
  esac

  # Debug
  # echo "escape $p_var_name = $escaped_arg"

  printf -v "$p_var_name" '%s' "$escaped_arg"
}

##
# Encodes a single HTTP BasicAuth login/pass pair.
#
# Uses htpasswd encryption, which is also used for docker-compose Traefik labels.
#
# @param 1 [optional] String : reg key. Defaults to 'basic_auth_creds'.
# @param 2 [optional] String : login. Defaults to 'admin'.
# @param 3 [optional] String : password. Defaults to generated random string.
#
# NB : This function writes its result to a variable subject to collision in
# calling scope.
#
# @var basic_auth_credentials
#
# @example
#   # Defaults to key 'basic_auth_creds' + login: admin, pass: (a randomly
#   # generated string) :
#   encoded_credentials="$(u_str_basic_auth_credentials)"
#   echo "$encoded_credentials"
#   # To read the randomly generated password, use :
#   u_instance_registry_get 'basic_auth_creds' # <- or whatever key was passed in 3rd arg.
#
#   # Specify key :
#   encoded_credentials="$(u_str_basic_auth_credentials 'custom_reg_namespace')"
#   echo "$encoded_credentials"
#
#   # Specify credentials :
#   encoded_credentials="$(u_str_basic_auth_credentials 'custom_reg_namespace' 'foo' 'bar')"
#   echo "$encoded_credentials"
#
u_str_basic_auth_credentials() {
  local p_key="$1"
  local p_user="$2"
  local p_pass="$3"

  if [[ -z "$p_key" ]]; then
    p_key='basic_auth_creds'
  fi
  if [[ -z "$p_user" ]]; then
    p_user='admin'
  fi

  # When no password is passed as argument, if there was no random password
  # already generated in current instance for given key, generate one.
  u_instance_registry_get "$p_key"
  if [[ -z "$p_pass" ]] && [[ -z "$reg_val" ]]; then
    p_pass=`< /dev/urandom tr -dc A-Za-z0-9 | head -c8; echo`
    u_instance_registry_set "$p_key" "$p_user:$p_pass"
  else
    u_str_split1 'split_arr' "$reg_val" ':'
    p_user="${split_arr[0]}"
    p_pass="${split_arr[1]}"
  fi

  # Update : because we're using an env. variable for credentials, we don't
  # actually need to escape dollar signs here.
  # echo "$p_user:$(openssl passwd -apr1 "$p_pass")" | sed -e s/\\$/\\$\\$/g
  echo "$p_user:$(openssl passwd -apr1 "$p_pass")"
}

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
# Joins space-separated items by given separator.
#
# This function writes its result in the following variable in calling scope :
# @var joined_str
#
# @param 1 String : separator.
# @param ... String : values to join.
#
# @see https://stackoverflow.com/a/23673883
# @see https://stackoverflow.com/a/17841619
#
# @example
#   # Do not use quotes around the string argument
#   joined_str=''
#   input_str='one two three four five'
#   u_str_join ', and ' $input_str
#   echo "$joined_str" # <- outputs 'one, and two, and three, and four, and five'
#
#   # Works with arrays too :
#   joined_str=''
#   a=( one two "three three" four five )
#   u_str_join '|' "${a[@]}"
#   echo "$joined_str" # <- outputs 'one|two|three three|four|five'
#
#   # Update Debian 12 : need to escape characters like '&' in separator :
#   joined_str=''
#   input_str='one two three four five'
#   u_str_join ' \&\& ' $input_str
#   echo "$joined_str" # <- outputs 'one && two && three && four && five'
#
u_str_join() {
  local p_sep=$1
  local IFS=
  if [[ -z "$p_sep" ]]; then
    p_sep='|'
  fi
  joined_str=$2
  shift 2 || shift $(($#))
  joined_str+="${*/#/$p_sep}"
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
