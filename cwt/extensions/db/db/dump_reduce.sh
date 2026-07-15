#!/usr/bin/env bash

##
# TODO [wip] Provide implementation to strip DB dumps from certain tables' data.
#
# TODO [evol] Can add as many table names as needed after 1st arg.
#
# @example
#   make db-dump-reduce 'path/to/dump/file.sql.gz' 'table_name'
#   # Or :
#   cwt/extensions/db/db/dump_reduce.sh 'path/to/dump/file.sql.gz' 'table_name'
#

. cwt/bootstrap.sh

db_dump_file="$1"

if [[ -z "$db_dump_file" || ! -f "$db_dump_file" ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO: arg 1 (dump file path) missing or inexisting." >&2
  echo "  -> Aborting (1)." >&2
  echo >&2
  exit 1
fi

table_to_skip="$2"

if [[ -z "$table_to_skip" ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO: arg 2 (DB table to skip) missing." >&2
  echo "  -> Aborting (2)." >&2
  echo >&2
  exit 2
fi

db_dump_dir="${db_dump_file%/${db_dump_file##*/}}"
db_dump_file_name="${db_dump_file##*/}"
db_dump_file_name="${db_dump_file_name%%.*}"
reduced_dump_file_name="${db_dump_file_name}.reduced.sql"
reduced_dump="${db_dump_dir}/$reduced_dump_file_name"

# Debug.
# echo "db_dump_file = $db_dump_file"
# echo "db_dump_dir = $db_dump_dir"
# echo "db_dump_file_name = $db_dump_file_name"
# echo "reduced_dump_file_name = $reduced_dump_file_name"
# echo "reduced_dump = $reduced_dump"
# exit

if [[ -f "$reduced_dump" ]]; then
  echo "The reduced_dump $reduced_dump already exists."
  echo "Aborting."
  exit
fi

# Query file may or may not be an archive. If it is, uncompress it.
extracted_file=''
compressed_file=''

u_fs_extract_in_place "$db_dump_file"

# Debug.
if [[ -n "$extracted_file" ]]; then
  echo "  extracted_file = $extracted_file"
fi

# When input file is an archive, we assume the uncompressed file will be
# named exactly like the archive without its extension, e.g. :
# - my-dump.sql.tgz -> my-dump.sql
# - my-dump.sql.tar.gz -> my-dump.sql
if [[ -f "$extracted_file" ]]; then
  echo "  Input file was compressed -> using extracted file '$extracted_file' as input."
  compressed_file="$db_dump_file"
  db_dump_file="$extracted_file"

  # Debug.
  echo "  compressed_file = $compressed_file"
  echo "  db_dump_file = $db_dump_file"
else
  # Debug.
  echo "  db_dump_file = $db_dump_file"
fi

if [[ ! -f "$db_dump_file" ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO: missing uncompressed dump file :" >&2
  echo "  $db_dump_file" >&2
  echo "  -> Aborting (3)." >&2
  echo >&2
  exit 3
fi

# Implementations MUST use var $db_dump_file as input path (source file).
#
# mysqldump wraps table data in LOCK TABLES ... UNLOCK TABLES. MariaDB 11+ may emit
# multi-line INSERTs (header line + one row per line); deleting INSERT lines only
# leaves orphan row data. Also skip bare INSERT blocks when LOCK TABLES is absent.
awk -v t="$table_to_skip" '
  function is_table_lock() {
    return index($0, "LOCK TABLES `" t "`") == 1
  }
  function is_table_insert() {
    return index($0, "INSERT INTO `" t "`") == 1
  }
  is_table_lock() { skip=1; next }
  skip && $0 == "UNLOCK TABLES;" { skip=0; next }
  skip { next }
  is_table_insert() { skip_insert=1; next }
  skip_insert && index($0, "INSERT INTO `") == 1 && !is_table_insert() { skip_insert=0 }
  skip_insert && index($0, "-- Table structure for table") == 1 { skip_insert=0 }
  skip_insert && $0 == "UNLOCK TABLES;" { skip_insert=0; next }
  skip_insert { next }
  { print }
' "$db_dump_file" > "$reduced_dump"

if [[ ! -f "$reduced_dump" ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO: failed to create reduced dump file :" >&2
  echo "  $reduced_dump" >&2
  echo "  -> Aborting (4)." >&2
  echo >&2
  exit 4
fi

if [[ -f "$extracted_file" && -f "$compressed_file" ]]; then
  # Rename old compressed dump (to keep as archive).
  mv "$compressed_file" "${db_dump_dir}/${db_dump_file_name}.before-reduce.sql.gz"

  # Compress & remove uncompressed dump file (gzip, not tar: restores use gunzip).
  gzip -c "$reduced_dump" > "${reduced_dump}.gz"

  if [[ $? -ne 0 ]]; then
    if [[ -f "${db_dump_dir}/${db_dump_file_name}.before-reduce.sql.gz" ]]; then
      mv "${db_dump_dir}/${db_dump_file_name}.before-reduce.sql.gz" "$compressed_file"
    fi

    if [[ -f "$reduced_dump.gz" ]]; then
      rm -f "$reduced_dump.gz"
    fi

    if [[ -f "$reduced_dump_file_name" ]]; then
      rm -f "$reduced_dump_file_name"
    fi

    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO: failed to compress dump file '$db_dump_file'." >&2
    echo "-> Aborting (5)." >&2
    echo >&2
    exit 5
  fi

  rm "$reduced_dump"
  rm "$db_dump_file"
fi
