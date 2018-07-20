#!/usr/bin/env bash

##
# Filesystem (fs) related utility functions.
#
# This file is sourced during core CWT bootstrap.
# @see cwt/bootstrap.sh
#
# Convention : functions names are all prefixed by "u" (for "utility").
#

##
# Recursively gets the last N most recent file(s) in given path.
#
# @param 1 [optional] String base path (defaults to '.').
# @param 2 [optional] Number number of most recent files to get (defaults to 1).
#
# @see https://stackoverflow.com/questions/4561895/how-to-recursively-find-the-latest-modified-file-in-a-directory
#
# @example
#   most_recent="$(u_fs_get_most_recent)"
#   echo "$most_recent"
#
#   # Gets the last modified file in path 'cwt' :
#   most_recent="$(u_fs_get_most_recent 'cwt')"
#   echo "$most_recent"
#
#   # Gets the last 3 files modified in path 'cwt' :
#   most_recent="$(u_fs_get_most_recent 'cwt' 3)"
#   echo "$most_recent"
#
u_fs_get_most_recent() {
  local p_path="$1"
  local p_max=$2

  if [[ -z "$p_path" ]]; then
    p_path='.'
  fi
  if [[ -z "$p_max" ]]; then
    p_max=1
  fi

  # TODO Mac OSX ?
  # find "$p_path" -type f -print0 \
  #   | xargs -0 stat -f "%m %N" \
  #   | sort -rn \
  #   | head -1 \
  #   | cut -f2- -d" "

  find "$p_path" -type f -printf '%T@ %p\n' \
    | sort -rn \
    | head -$p_max \
    | cut -f2- -d" "
}

##
# Reads file contents (without using subshell).
#
# @see https://stackoverflow.com/questions/7427262/how-to-read-a-file-into-a-variable-in-shell
#
# @example
#   my_file_contents=''
#   u_fs_get_file_contents 'cwt/.cwt_subjects_ignore' 'my_file_contents'
#   echo "$my_file_contents"
#
u_fs_get_file_contents() {
  local p_file_path="$1"
  local p_var_name="$2"

  if [[ ! -f "$p_file_path" ]]; then
    echo >&2
    echo "Error in u_fs_get_file_contents() - $BASH_SOURCE line $LINENO: file '$p_file_path' was not found." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    return 1
  fi

  u_str_sanitize_var_name "$p_var_name" 'p_var_name'

  local line=''
  local contents=''

  while read line; do
    contents+="$line
"
  done < "$p_file_path"

  printf -v "$p_var_name" '%s' "$contents"
}

##
# Lists folders (shorter naming choice : we use 'dir' for directories).
#
# NB : for performance reasons (to avoid using a subshell), this function
# writes its result to a variable subject to collision in calling scope.
#
# @var dir_list
#
# @param 1 [optional] String base path (defaults to '.').
# @param 2 [optional] String dir name filter pattern (defaults to none / not filtering).
# @param 3 [optional] Integer max depth (defaults to 1).
#
# @example
#   # List all dirs in current folder.
#   u_fs_dir_list
#   echo "$dir_list"
#
#   # List '*.sh' dirs in current folder.
#   u_fs_dir_list . '*.sh'
#   echo "$dir_list"
#
#   # List all dirs in the "/path/to/dir" folder up to 3 levels deep.
#   u_fs_dir_list /path/to/dir '' 3
#   echo "$dir_list"
#
u_fs_dir_list() {
  local p_path="$1"
  local p_filter_pattern="$2"
  local p_maxdepth=$3

  dir_list=''

  if [[ -z "$p_path" ]]; then
    p_path='.'
  fi

  if [[ -z "$p_maxdepth" ]]; then
    p_maxdepth=1
  fi

  local i

  # If we need to look for dirs in deeper levels, use 'find' (subshell).
  # TODO remove depth argument and make a separate function ? #YAGNI
  if [[ $p_maxdepth -gt 1 ]]; then
    if [[ -z "$p_filter_pattern" ]]; then
      dir_list="$(find "$p_path" -maxdepth "$p_maxdepth" -type d -printf '%P\n')"
    else
      dir_list="$(find "$p_path" -maxdepth "$p_maxdepth" -type d -name "$p_filter_pattern" -printf '%P\n')"
    fi

  # Otherwise, just use the less expensive bash loop.
  else
    if [[ "$p_path" != '.' ]]; then
      pushd "$p_path" >/dev/null
    fi

    # The default globbing in bash does not include dirnames starting with a .
    shopt -s dotglob

    if [[ -z "$p_filter_pattern" ]]; then
      for i in * ; do
        if [ -d "$i" ]; then
          dir_list+="${i}
"
        fi
      done
    else
      for i in * ; do
        if [ -d "$i" ]; then
          case "$i" in
            $p_filter_pattern)
              dir_list+="${i}
"
            ;;
          esac
        fi
      done
    fi

    if [[ "$p_path" != '.' ]]; then
      popd >/dev/null
    fi

    shopt -u dotglob
  fi
}

##
# Gets a list of files in given folder.
#
# NB : for performance reasons (to avoid using a subshell), this function
# writes its result to a variable subject to collision in calling scope.
#
# @var file_list
#
# @param 1 [optional] String base path (defaults to '.').
# @param 2 [optional] String file name filter pattern (defaults to '*' / not filtering).
# @param 3 [optional] Integer max depth (defaults to 1).
#
# @example
#   # List all files in current folder.
#   u_fs_file_list
#   echo "$file_list"
#
#   # List '*.sh' files in current folder.
#   u_fs_file_list . '*.sh'
#   echo "$file_list"
#
#   # List all files in the "/path/to/dir" folder up to 3 levels deep.
#   u_fs_file_list /path/to/dir '' 3
#   echo "$file_list"
#
u_fs_file_list() {
  local p_path="$1"
  local p_filter_pattern="$2"
  local p_maxdepth=$3

  file_list=''

  if [[ -z "$p_path" ]]; then
    p_path='.'
  fi

  if [[ -z "$p_maxdepth" ]]; then
    p_maxdepth=1
  fi

  local i

  # If we need to look for files in deeper levels, use 'find' (subshell).
  # TODO remove depth argument and make a separate function ? #YAGNI
  if [[ $p_maxdepth -gt 1 ]]; then
    if [[ -z "$p_filter_pattern" ]]; then
      file_list="$(find "$p_path" -maxdepth "$p_maxdepth" -type f -printf '%P\n')"
    else
      file_list="$(find "$p_path" -maxdepth "$p_maxdepth" -type f -name "$p_filter_pattern" -printf '%P\n')"
    fi

  # Otherwise, just use the less expensive bash loop.
  else
    if [[ "$p_path" != '.' ]]; then
      pushd "$p_path" >/dev/null
    fi

    # The default globbing in bash does not include filenames starting with a .
    shopt -s dotglob

    if [[ -z "$p_filter_pattern" ]]; then
      for i in * ; do
        if [ -f "$i" ]; then
          file_list+="${i}
"
        fi
      done
    else
      for i in * ; do
        if [ -f "$i" ]; then
          case "$i" in
            $p_filter_pattern)
              file_list+="${i}
"
            ;;
          esac
        fi
      done
    fi

    if [[ "$p_path" != '.' ]]; then
      popd >/dev/null
    fi

    shopt -u dotglob
  fi
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
# Adds or updates a single line in given file.
#
# NB : hasn't been tested when pattern matches several lines.
#
# @param 1 String : the matching pattern (recognizes which line to update).
# @param 2 String : the entire new line to write.
# @param 3 String : (writeable) file path.
#
# @example
#   u_fs_update_or_append_line 'MY_VAR=' 'MY_VAR="new-val"' path/to/writeable/file
#
u_fs_update_or_append_line() {
  local p_pattern="$1"
  local p_new_line="$2"
  local p_file_path="$3"

  if [[ ! -f "$p_file_path" ]]; then
    echo >&2
    echo "Error in u_fs_update_or_append_line() - $BASH_SOURCE line $LINENO: file $p_file_path was not found." >&2
    echo "Aborting (1)." >&2
    echo >&2
    return 1
  fi

  local haystack
  u_fs_get_file_contents "$p_file_path" 'haystack'
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

  local haystack
  u_fs_get_file_contents "$p_file_path" 'haystack'

  if [[ -z "$haystack" ]]; then
    echo "$p_needle" > "$p_file_path"
    return
  fi

  local new_str="$(u_str_append_once $'\n'"$p_needle" "$haystack")"

  if [[ "$new_str" != "$haystack" ]]; then
    echo "$new_str" > "$p_file_path"
  fi
}

##
# Replaces an entire line in given file.
#
# See https://stackoverflow.com/questions/11245144/replace-whole-line-containing-a-string-using-sed
#
# @example
#   u_fs_change_line "The existing line matching pattern" "The replacement text" path/to/file.ext
#
u_fs_change_line() {
  local p_existing_line_match="$1"
  local p_replacement="$2"
  local p_file="$3"

  local new=$(u_str_sed_escape "${p_replacement}")

  sed "/$p_existing_line_match/c $new" -i "$p_file"
}
