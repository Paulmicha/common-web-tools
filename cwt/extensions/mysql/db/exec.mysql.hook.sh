#!/usr/bin/env bash

##
# Implements u_hook_most_specific -s 'db' -a 'exec' -v 'DB_DRIVER DB_ID INSTANCE_TYPE PROVISION_USING'
#
# This file is dynamically included when the "hook" is triggered.
# @see u_db_exec() in cwt/extensions/db/db.inc.sh
#
# The following variables are available here :
#   - DB_ID - defaults to 'default'.
#   - DB_DRIVER - defaults to 'mysql'.
#   - DB_HOST - defaults to 'localhost'.
#   - DB_PORT - defaults to '3306' or '5432' if DB_DRIVER is 'pgsql'.
#   - DB_NAME - defaults to "*".
#   - DB_USER - defaults to first 16 characters of DB_ID.
#   - DB_PASS - defaults to 14 random characters.
#   - DB_ADMIN_USER - defaults to DB_USER.
#   - DB_ADMIN_PASS - defaults to DB_PASS.
#   - DB_TABLES_SKIP_DATA - defaults to an empty string.
# @see u_db_set() in cwt/extensions/db/db.inc.sh
#
# @example
#   make db-exec
#   # Or :
#   cwt/extensions/db/db/exec.sh
#

# Workaround : some .sql.gz dumps are tar.gz (legacy dump_reduce) or gunzip leaves a
# tar archive instead of SQL. Extract or trim until the file begins like a mysqldump.
# @see cwt/extensions/db/db/dump_reduce.sh
if file -b "$db_dump_file" 2>/dev/null | grep -q 'tar archive'; then
  dump_dir="${db_dump_file%/*}"
  dump_tar_extract_dir="$(mktemp -d "${dump_dir}/.dump_extract.XXXXXX")"

  tar -xf "$db_dump_file" -C "$dump_tar_extract_dir"

  if [[ $? -ne 0 ]]; then
    rm -rf "$dump_tar_extract_dir"
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO: failed to extract tar archive '$db_dump_file'." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    exit 1
  fi

  u_fs_file_list "$dump_tar_extract_dir"

  if [[ ${#file_list_arr[@]} -ne 1 ]]; then
    rm -rf "$dump_tar_extract_dir"
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO: expected a single file in tar archive '$db_dump_file'." >&2
    echo "-> Aborting (2)." >&2
    echo >&2
    exit 2
  fi

  mv "${dump_tar_extract_dir}/${file_list_arr[0]}" "$db_dump_file"
  rm -rf "$dump_tar_extract_dir"
else
  dump_first_line="$(head -1 "$db_dump_file")"

  if [[ -n "$dump_first_line" ]]; then
    case "$dump_first_line" in
      '--'*|'/*'*)
        ;;
      *)
        sed -i '1d' "$db_dump_file"
        ;;
    esac
  fi
fi

# Update 2024/08/16 - use the --binary-mode by default for error :
# ERROR at line 1047: ASCII '\0' appeared in the statement, but this is not
# allowed unless option --binary-mode is enabled and mysql is run in
# non-interactive mode.
case "$DB_NAME" in
  '*')
    mysql --binary-mode --default_character_set="$SQL_CHARSET" \
      --user="$DB_USER" \
      --password="$DB_PASS" \
      --host="$DB_HOST" \
      --port="$DB_PORT" \
      -B < "$db_dump_file"
    ;;
  *)
    mysql --binary-mode --default_character_set="$SQL_CHARSET" \
      --user="$DB_USER" \
      --password="$DB_PASS" \
      --host="$DB_HOST" \
      --port="$DB_PORT" \
      -B \
      "$DB_NAME" < "$db_dump_file"
    ;;
esac

# Update 2024/08/16 - retry without the '--binary-mode' option.
if [[ $? -ne 0 ]]; then
  echo "Retry without --binary-mode ..."

  . cwt/extensions/db/db/clear.sh

  case "$DB_NAME" in
    '*')
      mysql --default_character_set="$SQL_CHARSET" \
        --user="$DB_USER" \
        --password="$DB_PASS" \
        --host="$DB_HOST" \
        --port="$DB_PORT" \
        -B < "$db_dump_file"
      ;;
    *)
      mysql --default_character_set="$SQL_CHARSET" \
        --user="$DB_USER" \
        --password="$DB_PASS" \
        --host="$DB_HOST" \
        --port="$DB_PORT" \
        -B \
        "$DB_NAME" < "$db_dump_file"
      ;;
  esac

  # Fail if workaround didn't work.
  if [[ $? -ne 0 ]]; then
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO: unable to exec the queries in file '$db_dump_file' into $DB_DRIVER DB '$DB_NAME'." >&2
    echo "-> Aborting (2)." >&2
    echo >&2
    exit 2
  fi

  echo "Retry without --binary-mode : done."
fi
