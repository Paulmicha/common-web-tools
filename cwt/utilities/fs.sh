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
# Periodically checks files for changes (by modif. time) and runs given command.
#
# TODO [evol] Error handling (break on error).
#
# @param 1 String : lookup dir.
# @param 2 [optional] String : command to run. Has access to this function's
#   local variables such as $files_recently_changed.
#   Defaults to 'echo $files_recently_changed'.
# @param 3 [optional] String : 'find' name filter pattern.
# @param 4 [optional] Integer : number of seconds for the polling interval.
#   Defaults to 2.
#
# See https://stackoverflow.com/a/24789597
# See https://unix.stackexchange.com/a/238740/89774
#
# @example
#   # Print the list of modified files every 2 seconds, if any :
#   u_fs_watch_poll the/target/dir
#
#   # Run in parallel several file watcher polling (Ctrl+C to stop) :
#   u_fs_watch_poll the/target/dir 'npm run build' &
#   u_fs_watch_poll another/dir 'gulp build' &
#   wait
#
u_fs_watch_poll() {
  local p_path="$1"
  local p_callback="$2"
  local p_filter_pattern="$3"
  local p_polling_interval="$4"
  local name_arg=''
  local files_recently_changed=''

  if [[ -z "$p_callback" ]]; then
    p_callback='echo $files_recently_changed'
  fi
  if [[ -n "$p_filter_pattern" ]]; then
    name_arg="-name $p_filter_pattern"
  fi
  if [[ -z "$p_polling_interval" ]]; then
    p_polling_interval='2'
  fi

  while [[ true ]]; do
    files_recently_changed=$(find $p_path -type f $name_arg -newermt "-$p_polling_interval seconds")
    if [[ -n $files_recently_changed ]] ; then
      echo
      echo "u_fs_watch_poll() : changes detected in the folling file(s) : $files_recently_changed"
      echo "  -> calling '$p_callback' ..."
      echo
      eval "$p_callback"
    fi
    sleep $p_polling_interval
  done
}

##
# Recursively merges 2 folders together.
#
# @param 1 String : the source dir.
# @param 2 String : the destination dir.
# @param 3 [optional] String : 'no' to prevent existing files from being
#   overwritten. Default value : 'yes' (overwrite in case of conflict).
# @param 4 [optional] String : 'no' to prevent the source dir from being deleted
#   after the merging is done. Default value : 'yes'.
#
# @example
#   # Overwriting existing destination files in target dir :
#   u_fs_merge_dirs my/src/dir the/target/dir
#
#   # Preserving existing destination files in target dir :
#   u_fs_merge_dirs my/src/dir the/target/dir 'no'
#
#   # Overwriting existing destination files in target dir + not deleting the
#   # source dir : :
#   u_fs_merge_dirs my/src/dir the/target/dir 'yes' 'no'
#
#   # Preserving existing destination files in target dir + not deleting the
#   # source dir :
#   u_fs_merge_dirs my/src/dir the/target/dir 'no' 'no'
#
u_fs_merge_dirs() {
  local p_src="$1"
  local p_target="$2"
  local p_overwriting="$3"
  local p_remove_merged_src="$4"

  # Prerequisites checks.
  if [[ -z "$p_src" ]] || [[ ! -d "$p_src" ]] \
    || [[ -z "$p_target" ]] || [[ ! -d "$p_target" ]]
  then
    echo >&2
    echo "Error in u_fs_merge_dirs() - $BASH_SOURCE line $LINENO: invalid arguments." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    return 1
  fi

  # Default value for $3 : to overwrite existing files.
  if [[ -z "$p_overwriting" ]]; then
    p_overwriting='yes'
  fi

  # Default value for $4 : to delete the source dir afterwards.
  if [[ -z "$p_remove_merged_src" ]]; then
    p_remove_merged_src='yes'
  fi

  case "$p_overwriting" in
    # When overwriting existing files, we can use the 'tar' program to create an
    # exact copy of the source tree with the owner and permissions intact, and
    # if the target folder exists, only files that are already existing will be
    # overwritten.
    # See https://unix.stackexchange.com/a/373475 (adapted to avoid subshell)
    y*|Y*)

      tar -C "$p_src" -cBf - . | tar -C "$p_target" -xBf -

      if [[ $? -ne 0 ]]; then
        echo >&2
        echo "Error in u_fs_merge_dirs() - $BASH_SOURCE line $LINENO: unable to merge with file overwrite." >&2
        echo "-> Aborting (2)." >&2
        echo >&2
        return 2
      fi
      ;;

    # When not overwriting existing files, we need to proceed file by file.
    *)
      local file_list=''
      local f=''
      local leaf=''
      local base_path=''

      u_fs_file_list "$p_src" '' '99'

      for f in $file_list; do
        # Skip corresponding file in target dir if it already exists.
        if [[ -f "$p_target/$f" ]]; then
          continue
        fi

        # Ensure destination dir exists.
        case "$f" in *'/'*)
          leaf="${f##*/}"
          base_path="${f%/$leaf}"

          mkdir -p "$p_target/$base_path"

          if [[ $? -ne 0 ]]; then
            echo >&2
            echo "Error in u_fs_merge_dirs() - $BASH_SOURCE line $LINENO: unable to create target subdir '$p_target/$base_path'." >&2
            echo "-> Aborting (3)." >&2
            echo >&2
            return 3
          fi
        esac

        mv "$p_src/$f" "$p_target/$f"

        if [[ $? -ne 0 ]]; then
          echo >&2
          echo "Error in u_fs_merge_dirs() - $BASH_SOURCE line $LINENO: unable to move file '$p_src/$f' to '$p_target/$f'." >&2
          echo "-> Aborting (4)." >&2
          echo >&2
          return 4
        fi
      done
      ;;
  esac

  # Finally, remove the merged source dir if requested ('yes' by default).
  case "$p_remove_merged_src" in y*|Y*)
    rm -rf "$p_src"
    if [[ $? -ne 0 ]]; then
      echo >&2
      echo "Error in u_fs_merge_dirs() - $BASH_SOURCE line $LINENO: unable to delete source dir '$p_src'." >&2
      echo "-> Aborting (5)." >&2
      echo >&2
      return 5
    fi
  esac
}

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
#   # List all dirs whose name starts with '_' in current folder.
#   u_fs_dir_list . '_*'
#   echo "$dir_list"
#
#   # List all dirs in the "/path/to/dir" folder up to 3 levels deep.
#   u_fs_dir_list /path/to/dir '' 3
#   echo "$dir_list"
#
#   # Looping example :
#   for dir in $dir_list; do
#     echo "$dir"
#   done
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
#   # Looping example :
#   u_fs_file_list 'scripts/cwt/local/remote-instances'
#   for file in $file_list; do
#     rm "scripts/cwt/local/remote-instances/$file"
#   done
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
# NB : for performance reasons (to avoid using a subshell), this function
# writes its result to a variable subject to collision in calling scope.
#
# @var relative_path
#
# @param 1 String absolute path to convert to relative path (must start with '/').
# @param 2 [optional] String absolute reference path (must start with '/').
#   Defaults to "$PROJECT_DOCROOT" or "$PWD".
#
# @example
#   u_fs_relative_path "$PROJECT_DOCROOT/yetetets/testtset/fdsf.fd"
#   echo "$relative_path" # <- Prints : yetetets/testtset/fdsf.fd
#
#   u_fs_relative_path / /var/www/html
#   echo "$relative_path" # <- Prints : ../../../
#
#   u_fs_relative_path /var/www/yetetets/testtset/fdsf.fd /opt/app
#   echo "$relative_path" # <- Prints : ../../var/www/yetetets/testtset/fdsf.fd
#
u_fs_relative_path() {
  local p_target="$1"
  local p_source="$2"

  if [[ -z "$p_source" ]]; then
    p_source="${PROJECT_DOCROOT:=$PWD}"
  fi

  local result=""
  local common_part="$p_source"

  while [[ "${p_target#$common_part}" == "${p_target}" ]]; do
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
  forward_part="${p_target#$common_part}"

  # and now stick all parts together
  if [[ -n $result ]] && [[ -n $forward_part ]]; then
    result="$result$forward_part"
  elif [[ -n $forward_part ]]; then
    # extra slash removal
    result="${forward_part:1}"
  fi

  relative_path="$result"
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

##
# Compresses given path to a *.tgz archive file (customizable).
#
# Inside the archive, the path is relative to the input path - i.e. if I
# request path/to/folder the resulting archive will contain the contents of that
# folder (and NOT path/to/folder).
#
# @param 1 String : the path to compress.
# @param 2 [optional] String : the destination folder. Defaults to current dir.
# @param 3 [optional] String : preferred extension. Defaults to 'tgz'.
#
# @example
#   # Will compress given path to arhive file in current dir :
#   u_fs_compress path/to/file.ext
#   # -> Result : ./file.ext.tgz
#   u_fs_compress path/to/folder
#   # -> Result : ./folder.tgz
#
#   # Will compress given path to arhive file inside dir 'path/to' :
#   u_fs_compress path/to/file.ext path/to
#   # -> Result : path/to/file.ext.tgz
#   u_fs_compress path/to/folder path/to
#   # -> Result : path/to/folder.tgz
#
#   # Custom extension.
#   u_fs_compress path/to/folder path/to tar.gz
#   # -> Result : path/to/folder.tar.gz
#
u_fs_compress() {
  local p_path="$1"
  local p_folder="$2"
  local p_preferred_extension="$3"

  if [[ ! -f "$p_path" ]] && [[ ! -d "$p_path" ]]; then
    echo >&2
    echo "Notice in u_fs_compress() - $BASH_SOURCE line $LINENO: directory or file '$p_path' was not found." >&2
    echo "Aborting (1)." >&2
    echo >&2
    return 1
  fi

  if [[ -n "$p_folder" ]] && [[ ! -d "$p_folder" ]]; then
    echo >&2
    echo "Notice in u_fs_compress() - $BASH_SOURCE line $LINENO: directory '$p_folder' was not found." >&2
    echo "Aborting (2)." >&2
    echo >&2
    return 2
  fi

  # TODO adapt tar parameters below depending on chosen extension.
  # TODO [evol] support other compression programs ?
  local extension='tgz'
  if [[ -n "$p_preferred_extension" ]]; then
    extension="$p_preferred_extension"
  fi

  if [[ -n "$p_folder" ]]; then
    p_path="${p_path##*/}"
    tar -C "$p_folder" -czf "$p_folder/$p_path.$extension" "$p_path"
  else
    tar -czf "$p_path.$extension" "$p_path"
  fi

  return $?
}

##
# Same as u_fs_compress() but presetting folder to compress in place.
#
# @param 1 String : the path to compress.
#
# @see u_fs_compress()
#
# @example
#   # Will compress given path to arhive file inside dir 'path/to' :
#   u_fs_compress_in_place path/to/file.ext
#   # -> Result : path/to/file.ext.tgz
#   u_fs_compress_in_place path/to/folder
#   # -> Result : path/to/folder.tgz
#
u_fs_compress_in_place() {
  local p_path_to_compress_in_place="$1"
  local leaf="${p_path_to_compress_in_place##*/}"
  local base_path="${p_path_to_compress_in_place%/$leaf}"

  u_fs_compress \
    "$p_path_to_compress_in_place" \
    "$base_path"

  return $?
}

##
# Extracts given archive file(s). Supports various formats.
#
# This function uses a return value to indicate wether the file was uncompressed
# or not. It also sets the uncompressed file names to a variable
# subject to collision in calling scope :
# @var extracted_files
#
# If the archive contained a single file, it will set its name to the following
# variable subject to collision in calling scope :
# @var extracted_file
#
# @param 1 String : the archive file to extract.
# @param 2 [optional] String : the destination folder. Defaults to current dir.
#   TODO [wip] Only tested with tar program. We need to check other programs
#   behaviors (if they uncompress files in place or inside current folder).
#
# See https://github.com/xvoland/Extract
#
# This function deliberately does nothing if it does not detect a file extension
# matching some archive format whitelisted below.
#
# @example
#   # Extract given archive files in current dir :
#   extracted_files=''
#   u_fs_extract path/to/file.zip
#   echo "$extracted_files" # <- Outputs list of extracted contents.
#
#   # Extract given archive containing a single file to folder 'path/to' :
#   extracted_file=''
#   u_fs_extract path/to/file.sql.tgz path/to
#   echo "$extracted_file" # <- Outputs e.g. path/to/file.sql
#
#   # Will leave the file untouched because it is not an archive file :
#   u_fs_extract path/to/file.txt
#   echo $? # Will print '1' (indicates that the file was untouched).
#
u_fs_extract() {
  local p_file="$1"
  local p_folder="$2"

  if [[ ! -f "$p_file" ]]; then
    echo >&2
    echo "Notice in u_fs_extract() - $BASH_SOURCE line $LINENO: file '$p_file' was not found." >&2
    echo "Aborting (2)." >&2
    echo >&2
    return 2
  fi

  if [[ -n "$p_folder" ]] && [[ ! -d "$p_folder" ]]; then
    echo >&2
    echo "Notice in u_fs_extract() - $BASH_SOURCE line $LINENO: directory '$p_folder' was not found." >&2
    echo "Aborting (3)." >&2
    echo >&2
    return 3
  fi

  local untouched=0
  local needs_copy='y'
  local original_file="$p_file"

  # In order to correctly handle the 2nd parameter (destination folder), we
  # process the 'tar' command separately.
  case "$p_file" in *.cbt|*.tar.bz2|*.tar.gz|*.tar.xz|*.tbz2|*.tgz|*.txz|*.tar)
    needs_copy='n'

    # Get archive contents.
    # TODO Untested : *.tar.bz2 archives may need the '-j' flag.
    # TODO Check relative paths are correct.
    # TODO Too slow for big archives -> make optional ?
    local contents_list_str=$(tar -tf "$p_file")
    local contents_list_arr=($contents_list_str)
    if [[ ${#contents_list_arr[@]} -gt 1 ]]; then
      extracted_files="$contents_list_str"
      if [[ -n "$p_folder" ]]; then
        extracted_files=''
        local i
        for i in "${contents_list_arr[@]}"; do
          extracted_files+="$p_folder/$i
"
        done
      fi
    else
      extracted_file="$contents_list_str"
      if [[ -n "$p_folder" ]]; then
        extracted_file="$p_folder/$contents_list_str"
      fi
    fi

    if [[ -n "$p_folder" ]]; then
      tar -xf "$p_file" -C "$p_folder"
    else
      tar -xf "$p_file"
    fi

    if [[ $? -ne 0 ]]; then
      echo >&2
      echo "Error in u_fs_extract() - $BASH_SOURCE line $LINENO: the tar command exited with non-zero code." >&2
      echo "Aborting (4)." >&2
      echo >&2
      exit 4
    fi

    return
  esac

  # TODO [wip] check other programs behaviors (if they uncompress in place or
  # inside current folder).
  # if [[ -n "$p_folder" ]] && [[ "$needs_copy" == 'y' ]]; then
  #   cp "$p_file" "$p_folder/"
  #   p_file="$p_folder/${p_file##*/}"
  # fi

  # TODO [wip] untested + list contents.
  # See https://github.com/xvoland/Extract
  case "$p_file" in
    *.7z|*.arj|*.cab|*.cb7|*.chm|*.deb|*.dmg|*.iso|*.lzh|*.msi|*.pkg|*.rpm|*.udf|*.wim|*.xar)
                        7z x "$p_file" ;;
    *.gz)               gunzip -k "$p_file" ;;
    *.cbz|*.epub|*.zip) unzip "$p_file" ;;
    *.bz2)              bunzip2 "$p_file" ;;
    *.cbr|*.rar)        unrar x -ad "$p_file" ;;
    *.z)                uncompress "$p_file" ;;
    *.lzma)             unlzma "$p_file" ;;
    *.xz)               unxz "$p_file" ;;
    *.exe)              cabextract "$p_file" ;;
    *.cpio)             cpio -id < "$p_file" ;;
    *.cba|*.ace)        unace x "$p_file" ;;
    *)                  untouched=1 ;;
  esac

  # if [[ -n "$p_folder" ]] && [[ "$needs_copy" == 'y' ]]; then
  #   rm "$p_file"
  # fi

  return $untouched
}

##
# Same as u_fs_extract() but presetting folder to extract in place.
#
# @param 1 String : the archive file to extract.
#
# @see u_fs_extract()
#
# @example
#   # Will extract given archive file in its folder :
#   u_fs_extract_in_place path/to/file.ext.tgz
#
u_fs_extract_in_place() {
  local p_file_to_extract_in_place="$1"
  local leaf="${p_file_to_extract_in_place##*/}"
  local base_path="${p_file_to_extract_in_place%/$leaf}"

  u_fs_extract \
    "$p_file_to_extract_in_place" \
    "$base_path"

  return $?
}
