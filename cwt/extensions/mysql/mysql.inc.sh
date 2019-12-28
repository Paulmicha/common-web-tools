#!/usr/bin/env bash

##
# Mysql-specific database utility functions.
#
# This file is sourced during core CWT bootstrap.
# @see cwt/bootstrap.sh
#

##
# Extracts a single DB dump from a multi-DB dump file.
#
# Writes result to another file.
# See https://stackoverflow.com/a/25975930
#
# @param 1 String : the DB name to extract.
# @param 2 String : path to source multi-DB dump file (compressed or not).
# @param 3 [optional] String : path to output file (the single-DB dump).
#   Defaults to the name of the DB to extract in the same folder as the source.
#
# @example
#   # By default, the resulting file will be written in same dir as source file.
#   # E.g. /path/to/dump/the_db_name.sql.tgz
#   u_mysql_extract_from_dump 'the_db_name' 'path/to/dump/multi-db-dump.sql.tgz'
#
#   # Specify a filepath for output.
#   u_mysql_extract_from_dump \
#     'the_db_name' \
#     'path/to/dump/multi-db-dump.sql' \
#     'path/to/resulting/single_db_dump.sql'
#
u_mysql_extract_from_dump() {
  local p_db_name="$1"
  local p_dump_file_input="$2"
  local p_dump_file_output="$3"
  local compressed_dump_file_input=''

  if [[ ! -f "$p_dump_file_input" ]]; then
    echo >&2
    echo "Error in u_mysql_extract_from_dump() - $BASH_SOURCE line $LINENO: the DB dump file '$p_dump_file_input' is missing or inaccessible." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    exit 1
  fi

  # Source dump file may or may not be an archive. If it is, uncompress it.
  extracted_file=''
  u_fs_extract_in_place "$p_dump_file_input"
  if [[ -n "$extracted_file" ]] && [[ -f "$extracted_file" ]]; then
    echo "Input file was compressed -> using extracted file '$extracted_file' as input."
    compressed_dump_file_input="$p_dump_file_input"
    p_dump_file_input="$extracted_file"
  fi

  # Determine output file path (fallback) if none was specified.
  if [[ -z "$p_dump_file_output" ]]; then
    local leaf="${p_dump_file_input##*/}"
    local input_file_dir="${p_dump_file_input%/$leaf}"
    local input_file_ext="${p_dump_file_input##*.}"
    p_dump_file_output="$input_file_dir/$p_db_name.$input_file_ext"
    echo "Resulting file path was not specified -> using '$p_dump_file_output' as output."
  fi

  sed -n "/^-- Current Database: \`$p_db_name\`/,/^-- Current Database: \`/p" \
    "$p_dump_file_input" > "$p_dump_file_output"

  if [[ $? -ne 0 ]]; then
    echo >&2
    echo "Error in u_mysql_extract_from_dump() - $BASH_SOURCE line $LINENO: the sed command exited with non-zero status." >&2
    echo "-> Aborting (2)." >&2
    echo >&2
    if [[ -n "$compressed_dump_file_input" ]]; then
      rm "$p_dump_file_input"
    fi
    exit 2
  fi

  # Compress resulting DB dump & remove the uncompressed output file.
  u_fs_compress_in_place "$p_dump_file_output"
  if [[ $? -ne 0 ]]; then
    echo >&2
    echo "Error in u_mysql_extract_from_dump() - $BASH_SOURCE line $LINENO: unable to compress output dump file '$p_dump_file_output'." >&2
    echo "-> Aborting (3)." >&2
    echo >&2
    exit 3
  fi
  rm "$p_dump_file_output"

  if [[ -n "$compressed_dump_file_input" ]]; then
    echo "Removing uncompressed dump file '$p_dump_file_input' ..."
    rm "$p_dump_file_input"
    echo "Done."
  fi
}
