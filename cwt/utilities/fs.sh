#!/usr/bin/env bash

##
# Filesystem (fs) related utility functions.
#
# This file is dynamically loaded.
# @see cwt/bootstrap.sh
#
# Convention : functions names are all prefixed by "u" (for "utility").
#

##
# Adds or updates a single line in given file.
#
# NB : hasn't been tested when pattern matches several lines.
#
# @param 1 String : the matching pattern (recognizes which line to update).
# @param 2 String : the entire new line to write.
# @param 3 String : (writeable) file path.
#
# @example
#   u_fs_update_line 'MY_VAR=' 'MY_VAR="new-val"' path/to/writeable/file
#
u_fs_update_line() {
  local p_pattern="$1"
  local p_new_line="$2"
  local p_file_path="$3"

  if [[ ! -f "$p_file_path" ]]; then
    echo
    echo "Error in u_fs_update_line() - $BASH_SOURCE line $LINENO: file $p_file_path was not found." >&2
    echo "Aborting (1)." >&2
    echo
    return 1
  fi

  local haystack="$(< "$p_file_path")"
  if [[ -z "$haystack" ]]; then
    echo "$p_new_line" > "$p_file_path"
    return
  fi

  # Escape backslash, forward slash and ampersand for use as a sed replacement.
  # See https://stackoverflow.com/a/42727904
  p_new_line=$(echo "$p_new_line" | sed -e 's/[\/&]/\\&/g')

  sed -e "s,${p_pattern}.*,${p_new_line},g" -i "$p_file_path"
}

##
# Writes given string to a file only once.
#
# @param 1 String : the string to append to the file.
# @param 2 String : (writeable) file path.
#
# @example
#   u_fs_write_once '--test A' path/to/writeable/file # File contents appended.
#   u_fs_write_once '--test A' path/to/writeable/file # (unchanged)
#   u_fs_write_once '--test B' path/to/writeable/file # File contents appended.
#
u_fs_write_once() {
  local p_needle="$1"
  local p_file_path="$2"

  local haystack="$(< "$p_file_path")"

  if [[ -z "$haystack" ]]; then
    echo "$p_needle" > "$p_file_path"
    return
  fi

  local new_str="$(u_string_append_once $'\n'"$p_needle" "$haystack")"

  if [[ "$new_str" != "$haystack" ]]; then
    echo "$new_str" > "$p_file_path"
  fi
}

##
# Gets a list of folder by path and maxdepth.
#
# @param 1 [optional] String base path (defaults to '.').
# @param 2 [optional] Integer max depth (defaults to 1).
#
# @example
#   dir_list=$(u_fs_dir_list)
#   echo "$dir_list"
#
u_fs_dir_list() {
  local p_path="$1"
  local p_maxdepth="$2"

  local dir_list=''

  if [[ -z "$p_path" ]]; then
    p_path='.'
  fi

  if [[ -z "$p_maxdepth" ]]; then
    p_maxdepth=1
  fi

  dir_list="$(find $p_path -maxdepth $p_maxdepth -type d -printf '%P\n')"

  echo "$dir_list"
}

##
# Gets a list of files in given folder.
#
# @param 1 [optional] String base path (defaults to '.').
# @param 2 [optional] Integer max depth (defaults to 1).
# @param 3 [optional] name matching pattern (defaults to '*.sh').
#
# @example
#   file_list=$(u_fs_file_list)
#   echo "$file_list"
#
u_fs_file_list() {
  local p_path="$1"
  local p_maxdepth="$2"
  local p_match_pattern="$3"

  local file_list=''

  if [[ -z "$p_path" ]]; then
    p_path='.'
  fi

  if [[ -z "$p_maxdepth" ]]; then
    p_maxdepth=1
  fi

  if [[ -z "$p_match_pattern" ]]; then
    p_match_pattern='*.sh'
  fi

  file_list="$(find "$p_path" -maxdepth "$p_maxdepth" -type f -name "$p_match_pattern" -printf '%P\n')"

  echo "$file_list"
}

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
#   u_fs_relative_path "$PROJECT_DOCROOT/yetetets/testtset/fdsf.fd"  # -> 'yetetets/testtset/fdsf.fd'
#   u_fs_relative_path "/"                                           # -> '../../'
#   u_fs_relative_path "/var/www/yetetets/testtset/fdsf.fd"          # -> '../../var/www/yetetets/testtset/fdsf.fd'
#
u_fs_relative_path() {
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
#   FILE_ABS_PATH=$(u_fs_absolute_path ${BASH_SOURCE[0]})
#
u_fs_absolute_path() {
  echo $(cd "$(dirname "$1")" && pwd)/$(basename "$1")
}
