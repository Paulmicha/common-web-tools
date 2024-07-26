#!/usr/bin/env bash

##
# Contains DB-related utilities for any remote instance (not necessarily using CWT).
#
# Complements the 'db' extension (if enabled).
# @see cwt/extensions/db
#
# Convention : functions names are all prefixed by "u" (for "utility").
#

##
# TODO [wip]
# Gets the latest dump found in given remote for given DB ID.
#
# Uses the following var in calling scope :
#
# @var dumps_dict
#
# @param 1 [optional] String : remote id.
#   Defaults to 'prod'.
# @param 2 [optional] String : DB ID.
#   Defaults to 'default'.
# @param 2 [optional] String : var name to store the result.
#   Defaults to 'latest_dump'.
#
# @example
#   # Get the latest dump for 'default' DB :
#   latest_dump=''
#   u_remote_db_get_latest_dump 'prod'
#   echo "latest_dump = $latest_dump"
#
#   # Get the latest dump for 'api' DB :
#   latest_dump=''
#   u_remote_db_get_latest_dump 'prod' 'api'
#   echo "latest_dump = $latest_dump"
#
u_remote_db_get_latest_dump() {
  local p_remote_id="$1"
  local p_db_id="$2"
  local p_var_name="$3"

  if [[ -z "$p_remote_id" ]]; then
    p_remote_id='prod'
  fi

  if [[ -z "$p_db_id" ]]; then
    p_db_id='default'
  fi

  if [[ -z "$p_var_name" ]]; then
    p_var_name='latest_dump'
  fi

  # TODO [wip]
  # find . -maxdepth 1 -type f -exec ls -1t "{}" + | head -n1
}

##
# Given a remote instance ID (and optional DB ID), this function :
#
# - resolves DB dump file paths, converting any token found in the remote
#   instance definitions,
# - and if no cmd was explicitly defined, generates fallback commands to be
#   executed on the selected remote instance :
#   - to create the DB dump,
#   - to compress the dump file,
#   - to remove the uncompressed dump file.
#
# When "remote db dump", by default, look for all the databases that we need
# to dump. The result depends on the remote instances definitions (they can have
# only 1 database to dump, or many).
#
# @see scripts/cwt/local/remote-instances/${p_remote_id}.sh
# @see u_remote_instances_setup() in cwt/extensions/remote/remote.inc.sh
# @see cwt/extensions/remote_db/remote/db_dump.sh
#
# Uses the following dictionary which must already have been initialized in
# calling scope :
#
# @var dumps_dict
#
# @param 1 String : remote id.
# @param 2 [optional] String : restrict by DB ID.
#   Defaults to an empty string, meaning process all the DB found in given
#   remote instance.
#
# @example
#   declare -A dumps_dict
#   u_remote_db_prepare_dumps 'prod'
#
u_remote_db_prepare_dumps() {
  local p_remote_id="$1"
  local p_db_id="$2"

  u_remote_db_read_definition "$p_remote_id" "$p_db_id"

  local db_id=''
  local db_ids=()
  local cmd=''
  local cmds=()
  local dump_file=''

  u_db_get_ids

  for db_id in "${db_ids[@]}"; do
    if [[ -n "$p_db_id" ]]; then
      case "$db_id" in
        "$p_db_id")
          echo "  only for DB '$db_id' ..."
          ;;
        # Skip any non-matching DB ID on given remote.
        *)
          continue
          ;;
      esac
    fi

    # The remote instance definitions may already provide the dump command.
    if [[ -n "${dumps_dict[${db_id}.cmd]}" ]]; then
      # Debug.
      # echo "already provided cmd = '${dumps_dict[${db_id}.cmd]}'"

      # But still initialize the 'dir' key in dumps_dict.
      # @see cwt/extensions/remote_db/remote/db_dump.sh
      if [[ -n "${dumps_dict[${db_id}.base_dir]}" ]]; then
        dumps_dict["${db_id}.dir"]="${dumps_dict[${db_id}.base_dir]}/local"
      fi

      continue
    fi

    # We can't carry on without a file name (to write the result of the command)
    # or the destination dir.
    if [[ -z "${dumps_dict[${db_id}.file]}" ]] \
      || [[ -z "${dumps_dict[${db_id}.base_dir]}" ]]
    then
      # Missing definitions per BD ID are by design ; it's how we know if a
      # remote instance (a single machine) actually has the database to dump, or
      # if it is in another remote.
      continue
    fi

    # The destination dir must always be in a 'local' subfolder wherever they
    # are created. This makes easier to eventually restore DB dumps from other
    # instances (i.e. for instance restoring prod dumps on dev or preprod).
    dumps_dict["${db_id}.dir"]="${dumps_dict[${db_id}.base_dir]}/local"
    dump_file="${dumps_dict[${db_id}.dir]}/${dumps_dict[${db_id}.file]}"

    # Finally, prepare the fallback DB dump commands, hardcoded here for now.
    local db_type='mysql'

    if [[ -n "${dumps_dict[${db_id}.type]}" ]]; then
      db_type="${dumps_dict[${db_id}.type]}"
    fi

    # TODO [evol] implement as a hook to deal with each DB driver's specifics in
    # their own dedicated extension.
    # @see cwt/extensions/mysql
    # @see cwt/extensions/pgsql
    # @see cwt/extensions/drupalwt (e.g. could even define a 'drush' dump type).
    case "$db_type" in
      'mysql')
        # It's actually several commands. This is based on the existing
        # implementation from :
        # @see cwt/extensions/mysql/db/backup.mysql.hook.sh
        cmds=()

        # Write as if the env vars (for credentials) were the same as our own
        # 'mysql' CWT extension - using the env vars from the 'db' extension.
        # Then, if a mapping to different env vars is provided, we will replace
        # them in the generated command string below.
        # Do not use single quotes around those env vars (only double quotes).
        cmds+=('mysqldump --user="$DB_USER" --password="$DB_PASS" --host="$DB_HOST" --port="$DB_PORT" --single-transaction --no-data --allow-keywords --skip-triggers "$DB_NAME" > '"$dump_file")

        # TODO [evol] Support excluding data for specific tables ?
        # @see cwt/extensions/mysql/db/backup.mysql.hook.sh
        cmds+=('mysqldump --user="$DB_USER" --password="$DB_PASS" --host="$DB_HOST" --port="$DB_PORT" --single-transaction --no-create-info --allow-keywords "$DB_NAME" >> '"$dump_file")

        # Compress the dump.
        cmds+=("tar czf $dump_file.gz -C ${dumps_dict[${db_id}.dir]} ${dumps_dict[${db_id}.file]}")

        # Remove the uncompressed dump.
        cmds+=("rm $dump_file")

        # Build the final command (string initialized with item 0 + start the
        # loop below at item 1 to handle joining commands with '&&' ; makes the
        # remote exec abort on any error at any step).
        dumps_dict["${db_id}.cmd"]="${cmds[0]}"

        for cmd in "${cmds[@]:1}"; do
          dumps_dict["${db_id}.cmd"]+=" && $cmd"
        done

        # Convert variables to the env vars used on the remote (if any mapping
        # is provided in the remote instance definition).
        local vars_to_map='db_driver db_host db_port db_name db_user db_pass db_admin_user db_admin_pass'
        local VAR=''
        local DB_ID=''

        u_str_uppercase "$db_id" 'DB_ID'

        # (Make the var replacement more readable by reusing this local var).
        cmd="${dumps_dict[${db_id}.cmd]}"

        for var in $vars_to_map; do
          u_str_uppercase "$var" 'VAR'
          var="REMOTE_INSTANCE_DATA_DUMPS_${DB_ID}_ENV_MAP_${VAR}"
          val="${!var}"

          if [[ -z "$val" ]]; then
            continue
          fi

          # Debug.
          # echo "\$$VAR => \$$val"

          # TODO this replace is potentially destroying some vars if their
          # name contains another var name... It could be mitigated by executing
          # the replace in descending order of var name length, but it would
          # be "less brittle" to implement a proper regex here. As in :
          # @see u_remote_definition_tokens_replace()
          cmd="${cmd//\$$VAR/\$$val}"
        done

        # Store the "var rewritten" result.
        dumps_dict["${db_id}.cmd"]="$cmd"
        ;;
    esac

    # TODO [evol] also provide a default (fallback) for 'drush' type ?
    # Note about drush sql-dump :
    # /**
    #  * List of tables whose *data* is skipped by the 'sql-dump' and 'sql-sync'
    #  * commands when the "--structure-tables-key=common" option is provided.
    #  * You may add specific tables to the existing array or add a new element.
    #  */
    # $options['structure-tables']['common'] = array('cache', 'cache_*', 'history', 'search_*', 'sessions', 'watchdog');
  done
}

##
# Gets the info necessary to download one or all remote DB dump(s).
#
# This function resolves DB dump file paths, both on the remote instance and
# locally, converting any token found in the remote instance definitions.
#
# @see u_remote_db_prepare_dumps()
# @see cwt/extensions/remote_db/remote/db_download.sh
# @see scripts/cwt/local/remote-instances/${p_remote_id}.sh
# @see u_remote_instances_setup() in cwt/extensions/remote/remote.inc.sh
#
# Uses the following dictionary which must already have been initialized in
# calling scope :
#
# @var dumps_dict
#
# @param 1 String : remote id.
# @param 2 [optional] String : restrict by DB ID.
#   Defaults to an empty string, meaning process all the DB found in given
#   remote instance.
# @param 3 [optional] String : datestamp of the DB dump(s) to download.
#   Defaults to the latest dump (requires the symlink).
#
# @example
#   declare -A dumps_dict
#   u_remote_db_prepare_downloads 'prod'
#
u_remote_db_prepare_downloads() {
  local p_remote_id="$1"
  local p_db_id="$2"
  local p_datestamp="$3"

  # To download dumps, we need to have a place to store them locally.
  if [[ -z "$CWT_DB_DUMPS_BASE_PATH" ]]; then
    echo >&2
    echo "Error in u_remote_db_prepare_paths() - $BASH_SOURCE line $LINENO: missing CWT_DB_DUMPS_BASE_PATH env var." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    return 1
  fi

  u_remote_db_read_definition "$p_remote_id" "$p_db_id"

  local db_id=''
  local db_ids=()

  u_db_get_ids

  for db_id in "${db_ids[@]}"; do
    if [[ -n "$p_db_id" ]]; then
      case "$db_id" in
        "$p_db_id")
          echo "  only for DB '$db_id' ..."
          ;;
        # Skip any non-matching DB ID on given remote.
        *)
          continue
          ;;
      esac
    fi

    # Skip any remote that has no definition for this DB ID (i.e. it does not
    # have this DB).
    if [[ -z "${dumps_dict[${db_id}.base_dir]}" ]]; then
      continue
    fi

    # Without 'latest_symlink' and without 'p_datestamp', there's no easy way to
    # know which file to download (TODO [evol] get the latest by modif date).
    if [[ -z "$p_datestamp" ]] && [[ -z "${dumps_dict[${db_id}.latest_symlink]}" ]]; then
      echo >&2
      echo "Error in u_remote_db_prepare_paths() - $BASH_SOURCE line $LINENO: need at least either 'latest_symlink' or param 3 'p_datestamp' to know which file to download." >&2
      echo "-> Aborting (2)." >&2
      echo >&2
      return 2
    fi

    # The dir containing DB dumps of any instance on that same instance will
    # always be in a 'local' subfolder. This makes easier to eventually
    # manipulate DB dumps from other instances (e.g. 'prod' dumps on a 'dev'
    # instance).
    dumps_dict["${db_id}.remote_dump_dir"]="${dumps_dict[${db_id}.base_dir]}/local"
    dumps_dict["${db_id}.local_dump_dir"]="${CWT_DB_DUMPS_BASE_PATH}/${p_remote_id}"

    # TODO [wip] postpone datestamp remplacement, as it is tokenized and would
    # require some regex work to be able to generate the correct file name.
    if [[ -n "$p_datestamp" ]]; then
      # dumps_dict["${db_id}.remote_dump_file"]="${dumps_dict[${db_id}.file]}.gz"
      echo "WIP download by datestamp is not ready - meanwhile, use the latest symlink instead." >&2
      echo "-> Aborting (4)." >&2
      echo >&2
      return 4
    fi

    # All dump file names must be appended with the 'gz' extension.
    dumps_dict["${db_id}.remote_dump_file"]="${dumps_dict[${db_id}.latest_symlink]}.gz"
    dumps_dict["${db_id}.remote_dump_file_path"]="${dumps_dict[${db_id}.remote_dump_dir]}/${dumps_dict[${db_id}.remote_dump_file]}"
    dumps_dict["${db_id}.local_dump_file_path"]="${dumps_dict[${db_id}.local_dump_dir]}/${dumps_dict[${db_id}.remote_dump_file]}"
  done
}

##
# Reads the remote instance definition into 'dumps_dict'.
#
# Uses the following var in calling scope :
#
# @var dumps_dict
#
# @param 1 [optional] String : remote id.
#   Defaults to 'prod'.
# @param 2 [optional] String : DB ID.
#   Defaults to an empty string, meaning process all the DB found in given
#   remote instance.
# @param 3 [optional] String : space-separated list of suffixes.
#   Defaults to all the keys prefixed by 'data_dumps_'.
#
# @see u_remote_definition_get_keys() in cwt/extensions/remote/remote.inc.sh
#
# @example
#   # Read 'prod' DB details.
#   declare -A dumps_dict
#   u_remote_db_read_definition
#   for key in "${!u_remote_db_read_definition[@]}"; do
#     echo "$key = ${u_remote_db_read_definition[$key]}"
#   done
#
#   # Only a specific DB ID :
#   u_remote_db_read_definition 'prod' 'api'
#
#   # Only specific definitions :
#   u_remote_db_read_definition 'prod' 'api' 'dir file'
#
u_remote_db_read_definition() {
  local p_remote_id="$1"
  local p_db_id="$2"
  local p_definition_suffixes="$3"

  if [[ -z "$p_remote_id" ]]; then
    p_remote_id='prod'
  fi

  if [[ -z "$p_definition_suffixes" ]]; then
    keys=()
    u_remote_definition_get_keys

    for key in "${keys[@]}"; do
      case "$key" in 'data_dumps_'*)
        p_definition_suffixes+="$key "
      esac
    done
  fi

  # Only load remote instance definitions if necessary.
  if [[ -z "$REMOTE_INSTANCE_ID" || "$REMOTE_INSTANCE_ID" != "$p_remote_id" ]]; then
    u_remote_instance_load "$p_remote_id"
  fi

  local var=''
  local val=''
  local db_id=''
  local db_ids=()
  local tokens_replaced=''
  local suffix=''
  local SUFFIX=''
  local dump_file=''

  u_db_get_ids

  for db_id in "${db_ids[@]}"; do
    if [[ -n "$p_db_id" ]]; then
      case "$db_id" in
        # Do nothing.
        "$p_db_id") val='' ;;
        # Skip any non-matching DB ID on given remote.
        *) continue ;;
      esac
    fi

    # Debug.
    # echo "  p_definition_suffixes = '$p_definition_suffixes'"

    for suffix in $p_definition_suffixes; do
      # Restrict to current DB ID.
      case "$suffix" in
        # Do nothing.
        "data_dumps_${db_id}_"*) val='' ;;
        # Skip any non-matching DB ID.
        *) continue ;;
      esac

      u_str_uppercase "$suffix" 'SUFFIX'

      # var="REMOTE_INSTANCE_DATA_DUMPS_${DB_ID}_${SUFFIX}"
      var="REMOTE_INSTANCE_${SUFFIX}"
      val="${!var}"

      if [[ -z "$val" ]]; then
        continue
      fi

      # Because of the way the suffix are filtered, here, we need to prune the
      # lowercase part. See 'p_definition_suffixes' (param 3).
      suffix=${suffix/"data_dumps_${db_id}_"/}

      # No need to re-process whatt's already done.
      # Update : doing this would prevent correct subsequent calls to load other
      # instances in the same scope.
      # if [[ -n "${dumps_dict[${db_id}.${suffix}]}" ]]; then
      #   continue
      # fi

      # When tokens are found, keep the raw value too ('.raw' suffix).
      case "$val" in *'{{ '*)
        dumps_dict["${db_id}.${suffix}.raw"]="$val"
      esac

      tokens_replaced=''
      u_remote_definition_tokens_replace "$p_remote_id" "$val"

      # Debug.
      # echo "$var = $val"
      # echo "$suffix = $val"
      # echo "$suffix = '$tokens_replaced'"
      # echo "$suffix = '$tokens_replaced'"
      # echo "  dumps_dict[${db_id}.${suffix}] = $tokens_replaced"

      dumps_dict["${db_id}.${suffix}"]="$tokens_replaced"
    done
  done
}
