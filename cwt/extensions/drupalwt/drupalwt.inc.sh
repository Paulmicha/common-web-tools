#!/usr/bin/env bash

##
# Docker4drupal utility functions.
#
# This file is sourced during core CWT bootstrap.
# @see cwt/bootstrap.sh
#
# Convention : functions names are all prefixed by "u" (for "utility").
#

##
# (re)Writes settings files where appropriate, e.g. :
#
# - sites/*/settings.php (copied from Drupal core default if non-existing)
# - sites/*/settings.local.php (if DWT_USE_SETTINGS_LOCAL_OVERRIDE = true)
# - sites/sites.php (if this is a multi-site setup)
#
# @requires the following globals in calling scope :
#   - DWT_MULTISITE
#   - DWT_MANAGE_SETTINGS_FILES
#
# @example
#   u_dwt_write_settings
#
u_dwt_write_settings() {
  # Multi-DB (manually set using the CWT_DB_IDS global) support.
  # It is necessary to load every prefixed DB var before (re)writing Drupal
  # settings in case those use multiple databases (thus need those vars loaded
  # already).
  # @see u_dwt_write_drupal_settings()
  local db_id=''
  for db_id in $CWT_DB_IDS; do
    u_db_set "$db_id"
  done

  case "$DWT_MULTISITE" in

    # Multi-site support.
    true)
      local site_id

      u_dwt_sites

      # Each site's DB is managed as a distinct DB_ID. First, we load every
      # site-specific prefixed DB var in order to export them all at once.
      # It is necessary to load every prefixed DB var before (re)writing Drupal
      # settings in case those use multiple databases (thus need those vars
      # loaded already).
      # @see u_dwt_write_drupal_settings()
      for site_id in "${dwt_sites_ids[@]}"; do
        u_db_set "$site_id"
      done

      # (Re)write Drupal settings files (e.g. sites/*/settings.php) for every site.
      case "$DWT_MANAGE_SETTINGS_FILES" in true)
        for site_id in "${dwt_sites_ids[@]}"; do
          u_dwt_write_drupal_settings "$site_id"
        done
      esac

      # (Re)write the multi-site declaration settings file (i.e. sites/sites.php).
      # TODO [evol] Support custom output file (i.e. sites/sites_local.php)
      # + base file ?
      case "$DWT_MANAGE_MULTISITE_SETTINGS_FILE" in true)
        u_dwt_write_multisite_settings
      esac
      ;;

    # "Normal" setups : just write the Drupal settings file.
    *)
      case "$DWT_MANAGE_SETTINGS_FILES" in true)
        u_dwt_write_drupal_settings
      esac
      ;;
  esac
}

##
# (Re)writes Drupal local settings files.
#
# Creates or override the 'settings.local.php' file for local project instance
# based on the most specific "template" match found.
#
# Also replaces custom "token" values using the following convention, e.g. :
# '{{ DRUPAL_HASH_SALT }}' becomes "$DRUPAL_HASH_SALT" (value).
#
# @requires the following globals in calling scope :
#   - DRUPAL_VERSION
#   - DRUPAL_SETTINGS_FILE
#   - DRUPAL_SETTINGS_LOCAL_FILE
#   - DWT_USE_SETTINGS_LOCAL_OVERRIDE
#
# Uses the following variable in calling scope :
#   - dwt_sites_ids (if available)
#
# To list matches & check which one will be used (the most specific) :
# $ p_site='my_site_id'
#   u_hook_most_specific 'dry-run' \
#     -s 'app' \
#     -a 'drupal_settings' \
#     -c 'tpl.php' \
#     -v 'DRUPAL_VERSION HOST_TYPE INSTANCE_TYPE p_site' \
#     -t -d
#   echo "match = $hook_most_specific_dry_run_match"
#
u_dwt_write_drupal_settings() {
  local p_site="$1"
  local f
  local line
  local var_val
  local var_name
  local var_name_c
  local token_prefix='{{ '
  local token_suffix=' }}'
  local hook_most_specific_dry_run_match=''

  if [[ -z "$p_site" ]]; then
    p_site='default'
  fi

  # Drupal settings template variants allow using separate files by site ID.
  u_hook_most_specific 'dry-run' \
    -s 'app' \
    -a 'drupal_settings' \
    -c 'tpl.php' \
    -v 'DRUPAL_VERSION HOST_TYPE INSTANCE_TYPE p_site' \
    -t

  # No declaration file found ? Can't carry on, there's nothing to do.
  if [[ ! -f "$hook_most_specific_dry_run_match" ]]; then
    echo >&2
    echo "Error in u_dwt_write_settings() - $BASH_SOURCE line $LINENO: no Drupal settings template file was found." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    return 1
  fi

  # Get dir name from multi-site setup (if available).
  local site_dir='default'
  local site_dir_var="dwt_sites_${p_site}_dir"
  u_str_sanitize_var_name "$site_dir_var" 'site_dir_var'
  if [[ -n "${!site_dir_var}" ]]; then
    site_dir="${!site_dir_var}"
  fi

  # Adjust the file settings path according to $p_site.
  local drupal_default_settings="$DRUPAL_SETTINGS_FILE"
  drupal_default_settings=${drupal_default_settings/'sites/default'/"sites/$site_dir"}

  # Support using local settings overrides. It's the difference between writing
  # everything in the settings.php file, or keeping it versionned and having it
  # include a settings.local.php file (kept out of the project repo). That way
  # we can have a shared, common set of settings and only generate dynamically
  # the ones really specific to all the different instances, which can also
  # override anything from the settings.php file.
  local drupal_settings="$DRUPAL_SETTINGS_FILE"
  case "$DWT_USE_SETTINGS_LOCAL_OVERRIDE" in 1|y*|true)
    drupal_settings="$DRUPAL_SETTINGS_LOCAL_FILE"
  esac
  drupal_settings=${drupal_settings/'sites/default'/"sites/$site_dir"}

  # Skip step if Drupal app codebase isn't initialized yet.
  if [[ ! -f "$drupal_default_settings" ]] && [[ ! -f "$SERVER_DOCROOT/sites/default/default.settings.php" ]]; then
    return
  fi

  # Console feedback.
  echo "(Re)write Drupal local settings file ($drupal_settings) ..."
  echo "  using template : $hook_most_specific_dry_run_match ..."

  case "$DWT_USE_SETTINGS_LOCAL_OVERRIDE" in 1|y*|true)

    # If the "normal" settings file does not exist and we're using local settings
    # overrides, we're going to need the default settings file (thant includes the
    # override) -> create it from Drupal core default.settings.php.
    if [[ ! -f "$drupal_default_settings" ]]; then

      echo "  the required base file $drupal_default_settings doesn't exist"
      echo "    -> create one using Drupal core default.settings.php ..."

      cp "$SERVER_DOCROOT/sites/default/default.settings.php" "$drupal_default_settings"
      if [[ $? -ne 0 ]]; then
        echo >&2
        echo "Error in u_dwt_write_drupal_settings() - $BASH_SOURCE line $LINENO: failed to copy Drupal core default.settings.php to '$drupal_default_settings'." >&2
        echo "-> Aborting (2)." >&2
        echo >&2
        exit 2
      fi

      # Enable the settings.local.php override inside it.
      cat >> "$drupal_default_settings" <<'EOF'

// Load local development override configuration, if available.
if (file_exists($app_root . '/' . $site_path . '/settings.local.php')) {
  include $app_root . '/' . $site_path . '/settings.local.php';
}
EOF
      echo "    $drupal_default_settings sucessfully created, with settings.local.php override enabled."

      # Keep write-protection.
      chmod "$FS_P_FILES" "$drupal_default_settings"
      if [[ $? -ne 0 ]]; then
        echo >&2
        echo "Error in $BASH_SOURCE line $LINENO: chmod exited with non-zero status." >&2
        echo "-> Aborting (5)." >&2
        echo >&2
        exit 5
      fi

    # In case the file already exists, make sure it includes our override.
    # This is done by detecting the presence of the line doing the include
    # in order to avoid appending it more than once (idempotence).
    else
      local haystack
      u_fs_get_file_contents "$drupal_default_settings" 'haystack'
      if [[ -z "$haystack" ]] || [[ "$haystack" != *"/settings.local.php"* ]]; then
        # Avoid errors due to file permissions.
        chmod u+w "$drupal_default_settings"
        cat >> "$drupal_default_settings" <<'EOF'

// Load local development override configuration, if available.
if (file_exists($app_root . '/' . $site_path . '/settings.local.php')) {
  include $app_root . '/' . $site_path . '/settings.local.php';
}
EOF
      fi
    fi
  esac

  # Replace $drupal_settings file with the matching template and replace its
  # "token" values.
  if [[ -f "$drupal_settings" ]]; then
    rm -f "$drupal_settings"
    if [[ $? -ne 0 ]]; then
      echo >&2
      echo "Error in u_dwt_write_drupal_settings() - $BASH_SOURCE line $LINENO: failed to replace the file '$drupal_settings'." >&2
      echo "-> Aborting (3)." >&2
      echo >&2
      exit 3
    fi
  fi

  # Avoid errors due to file permissions.
  chmod u+w "$SERVER_DOCROOT/sites/$site_dir"
  cp "$hook_most_specific_dry_run_match" "$drupal_settings"

  if [[ $? -ne 0 ]]; then
    echo >&2
    echo "Error in u_dwt_write_drupal_settings() - $BASH_SOURCE line $LINENO: failed to copy template $hook_most_specific_dry_run_match to '$drupal_settings'." >&2
    echo "-> Aborting (4)." >&2
    echo >&2
    exit 4
  fi

  # Start with read-only global vars (supports any global).
  u_global_list
  for var_name in "${cwt_globals_var_names[@]}"; do
    if grep -Fq "${token_prefix}${var_name}${token_suffix}" "$drupal_settings"; then
      var_val="${!var_name}"

      # Drupal settings require some specific paths to be relative to the Drupal
      # install dir ($SERVER_DOCROOT), like :
      #   "$PROJECT_DOCROOT/$APP_DOCROOT/config/sync" => '../config/sync'
      case "$var_name" in DRUPAL_FILES_DIR|DRUPAL_CONFIG_SYNC_DIR)
        # If the value does not start with '/', we assume it is relative to
        # PROJECT_DOCROOT. It must be absolute for the conversion to work.
        if [[ "${var_val:0:1}" != '/' ]]; then
          var_val="$PROJECT_DOCROOT/$var_val"
        fi
        u_fs_relative_path "$var_val" "$SERVER_DOCROOT"
        var_val="$relative_path"
      esac

      # Docker-compose specific : container paths are different, and CWT needs
      # both -> use variable name convention : if a variable named like the
      # current one with a '_C' suffix, it will automatically be used instead.
      # TODO [evol] Caveat : does not work if suffixed var value is empty.
      # @see cwt/extensions/drupalwt/app/global.docker-compose.vars.sh
      case "$PROVISION_USING" in docker-compose)
        var_name_c="${var_name}_C"
        if [[ -n "${!var_name_c}" ]]; then
          var_val="${!var_name_c}"
          case "$var_name_c" in DRUPAL_FILES_DIR_C|DRUPAL_CONFIG_SYNC_DIR_C)
            # If the value does not start with '/', in the case of
            # project instances using docker-compose, we assume it is relative
            # to APP_DOCROOT_C. It must be absolute for the conversion to work.
            if [[ "${var_val:0:1}" != '/' ]] && [[ "${APP_DOCROOT_C:0:1}" == '/' ]]; then
              var_val="$APP_DOCROOT_C/$var_val"
            fi
            u_fs_relative_path "$var_val" "$SERVER_DOCROOT_C"
            var_val="$relative_path"
          esac
        fi
      esac

      sed -e "s,${token_prefix}${var_name}${token_suffix},${var_val},g" -i "$drupal_settings"
      # echo "  [$p_site] replaced global '${token_prefix}${var_name}${token_suffix}' by '${var_val}'"
    fi
  done

  # Now, deal with DB-related variables (not necessarily globals). Any prefixed
  # or unprefixed DB_* var, including other site's, are supported everywhere.
  # All prefixed DB_* vars are already available in current scope.
  # @see u_dwt_write_settings()
  local unique_db_ids=()

  # First, reset unprefixed DB_* vars to current site's.
  u_db_set "$p_site"
  local v=''
  local site_id=''
  local db_vars=''
  u_db_vars_list
  for v in $db_vars_list; do
    db_vars+="DB_${v} "
  done

  # Multi-site DB support.
  if [[ -n "${dwt_sites_ids[@]}" ]]; then
    for site_id in "${dwt_sites_ids[@]}"; do
      unique_db_ids+=("$site_id")
      u_str_uppercase "$site_id" 'site_id'
      for v in $db_vars_list; do
        db_vars+="${site_id}_DB_${v} "
      done
    done
  fi

  # Multi-DB (manually set using the CWT_DB_IDS global) support.
  local db_id=''
  for db_id in $CWT_DB_IDS; do
    if u_in_array "$db_id" unique_db_ids; then
      continue
    fi
    unique_db_ids+=("$db_id")
    u_str_uppercase "$db_id" 'db_id'
    for v in $db_vars_list; do
      db_vars+="${db_id}_DB_${v} "
    done
  done

  # Now we're looping through all these possibilities and replace all matching
  # token(s), if any was found in the settings template used.
  for var_name in $db_vars; do
    if grep -Fq "${token_prefix}${var_name}${token_suffix}" "$drupal_settings"; then
      sed -e "s,${token_prefix}${var_name}${token_suffix},${!var_name},g" -i "$drupal_settings"
      # echo "  [$p_site] replaced '${token_prefix}${var_name}${token_suffix}' by '${!var_name}'"
    fi
  done

  # One more thing for multi-site setups : all keys from parsed YAML entries
  # must also map to tokenized variable names (which aren't globals).
  case "$DWT_MULTISITE" in true)
    local multisite_key
    local multisite_var
    u_dwt_sites_yml_keys

    for multisite_key in $dwt_sites_yml_keys; do
      # Except for 'config_sync_dir', which is handled below due to relative
      # path conversion.
      case "$multisite_key" in config_sync_dir)
        continue
      esac

      var_name="SITE_${multisite_key}"
      u_str_uppercase "$var_name" 'var_name'
      multisite_var="dwt_sites_${p_site}_${multisite_key}"
      u_str_sanitize_var_name "$multisite_var" 'multisite_var'
      var_val="${!multisite_var}"

      if grep -Fq "${token_prefix}${var_name}${token_suffix}" "$drupal_settings"; then
        sed -e "s,${token_prefix}${var_name}${token_suffix},$var_val,g" -i "$drupal_settings"
        # echo "  [$p_site] replaced multisite key '${token_prefix}${var_name}${token_suffix}' by '$var_val'"
      fi
    done

    # Writeable paths are dealt with like this : the globals that would apply
    # to the default site (like in mono-site setups) are renamed in the settings
    # file template by replacing the "DRUPAL_" prefix with "SITE_".
    # So instead of having for instance :
    #   $settings['file_public_path'] = '{{ DRUPAL_FILES_DIR }}';
    # in case of multi-sites setups, we would use :
    #   $settings['file_public_path'] = '{{ SITE_FILES_DIR }}';
    # @see u_dwt_get_sites_writeable_paths()
    local multisite_writeable_paths_varnames=()
    multisite_writeable_paths_varnames+=("SITE_FILES_DIR")
    multisite_writeable_paths_varnames+=("SITE_TMP_DIR")
    # multisite_writeable_paths_varnames+=("SITE_TRANSLATION_DIR")
    multisite_writeable_paths_varnames+=("SITE_CONFIG_SYNC_DIR")
    multisite_writeable_paths_varnames+=("SITE_PRIVATE_DIR")

    dwt_sites_writeable_paths=()
    case "$PROVISION_USING" in
      docker-compose)
        u_dwt_get_sites_writeable_paths "$p_site" 'dc'
        ;;
      *)
        u_dwt_get_sites_writeable_paths "$p_site"
        ;;
    esac

    for (( i = 0 ; i < ${#multisite_writeable_paths_varnames[@]} ; i++ )); do
      var_name="${multisite_writeable_paths_varnames[$i]}"
      var_val="${dwt_sites_writeable_paths[$i]}"

      case "$var_name" in SITE_FILES_DIR|SITE_CONFIG_SYNC_DIR)
        case "$PROVISION_USING" in
          docker-compose)
            # If the value does not start with '/', in the case of
            # project instances using docker-compose, we assume it is relative
            # to APP_DOCROOT_C. It must be absolute for the conversion to work.
            if [[ "${var_val:0:1}" != '/' ]] && [[ "${APP_DOCROOT_C:0:1}" == '/' ]]; then
              var_val="$APP_DOCROOT_C/$var_val"
            fi
            u_fs_relative_path "$var_val" "$SERVER_DOCROOT_C"
            ;;
          *)
            # If the value does not start with '/', we assume it is relative to
            # PROJECT_DOCROOT. It must be absolute for the conversion to work.
            if [[ "${var_val:0:1}" != '/' ]]; then
              var_val="$PROJECT_DOCROOT/$var_val"
            fi
            u_fs_relative_path "$var_val" "$SERVER_DOCROOT"
            ;;
        esac
        var_val="$relative_path"
      esac

      if grep -Fq "${token_prefix}${var_name}${token_suffix}" "$drupal_settings"; then
        sed -e "s,${token_prefix}${var_name}${token_suffix},$var_val,g" -i "$drupal_settings"
        # echo "  [$p_site] replaced writeable path '${token_prefix}${var_name}${token_suffix}' by '$var_val'"
      fi
    done
  esac

  # Keep write-protection.
  u_instance_get_permissions
  chmod "$FS_P_FILES" "$drupal_settings"
  if [[ $? -ne 0 ]]; then
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO: chmod exited with non-zero status." >&2
    echo "-> Aborting (6)." >&2
    echo >&2
    exit 6
  fi

  echo "(Re)write Drupal local settings file ($drupal_settings) : done."
  echo
}

##
# Multi-site : gets sites configuration, optionally filtered by given site.
#
# If the following variable is defined in calling scope, it will be used to
# add lookup paths when loading the sites YAML definition file :
# @var dwt_remote_id
#
# This function writes its results to variables subject to collision in calling
# scope :
# @var dwt_sites_ids
# @var dwt_sites_<SITE_ID>_domain
# @var dwt_sites_<SITE_ID>_dir
# @var dwt_sites_<SITE_ID>_install_profile
# @var dwt_sites_<SITE_ID>_config_sync_dir
# @var dwt_sites_<SITE_ID>_db_* (id, name, host, port, user, etc.)
#
# To list matches & check which one will be used (the most specific) :
# u_hook_most_specific 'dry-run' \
#   -s 'app' \
#   -a 'sites' \
#   -c 'yml' \
#   -v 'HOST_TYPE INSTANCE_TYPE' \
#   -t -r -d
# echo "match = $hook_most_specific_dry_run_match"
#
# Idem, but for a specific host remote ID :
# dwt_remote_id='preprod'
# u_hook_most_specific 'dry-run' \
#   -s 'app' \
#   -a 'sites' \
#   -c 'yml' \
#   -v 'HOST_TYPE INSTANCE_TYPE dwt_remote_id' \
#   -t -r -d
# echo "match = $hook_most_specific_dry_run_match"
#
# @example
#   # Get all sites config :
#   u_dwt_sites_yml_keys
#   u_dwt_sites
#   for site_id in "${dwt_sites_ids[@]}"; do
#     for key in $dwt_sites_yml_keys; do
#       var="dwt_sites_${site_id}_${key}"
#       val="${!var}"
#       echo "${site_id}.${key} = '$val'"
#     done
#   done
#
#   # Get a single site config :
#   u_dwt_sites_yml_keys
#   u_dwt_sites 'my_site_id'
#   for key in $dwt_sites_yml_keys; do
#     var="dwt_sites_my_site_id_${key}"
#     val="${!var}"
#     echo "$key = '$val'"
#   done
#
#   # Get sites IDs only :
#   u_dwt_sites '*' 'ids_only'
#   echo "There are ${#dwt_sites_ids[@]} sites defined in this local instance."
#   for site_id in "${dwt_sites_ids[@]}"; do
#     echo "$site_id"
#   done
#
#   # Get all sites config for given remote ID :
#   dwt_remote_id='preprod'
#   u_dwt_sites
#
u_dwt_sites() {
  local p_site="$1"
  local p_want="$2"
  local dwt_vars_prefix='dwt_sites_'
  local sites_parsed_yaml_str=''
  local hook_most_specific_dry_run_match=''
  local hook_variants

  # Sites YAML definition variants must allow using separate files by remote ID.
  hook_variants='HOST_TYPE INSTANCE_TYPE'
  if [[ -n "$dwt_remote_id" ]]; then
    hook_variants='HOST_TYPE INSTANCE_TYPE dwt_remote_id'
  fi

  # Defaults to dealing with all sites.
  if [[ -z "$p_site" ]]; then
    p_site='*'
  fi

  u_hook_most_specific 'dry-run' \
    -s 'app' \
    -a 'sites' \
    -c 'yml' \
    -v "$hook_variants" \
    -t -r

  # Immediately empty the variable triggering remote sites lookups in case this
  # function gets called again without needing it.
  if [[ -n "$dwt_remote_id" ]]; then
    dwt_remote_id=''
  fi

  # No declaration file found ? Can't carry on, there's nothing to do.
  if [[ ! -f "$hook_most_specific_dry_run_match" ]]; then
    echo >&2
    echo "Error in u_dwt_sites() - $BASH_SOURCE line $LINENO: no multi-sites declaration was found." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    return 1
  fi

  # Use pseudo-memoization to reduce multiple calls impact.
  if [[ -n "$memoized_dwt_sites_parsed_yaml_str" ]] \
    && [[ -n "$memoized_dwt_sites_yaml_file" ]] \
    && [[ "$hook_most_specific_dry_run_match" == "$memoized_dwt_sites_yaml_file" ]]
  then
    sites_parsed_yaml_str="$memoized_dwt_sites_parsed_yaml_str"
  else
    sites_parsed_yaml_str="$(u_yaml_parse "$hook_most_specific_dry_run_match" "$dwt_vars_prefix")"
    memoized_dwt_sites_parsed_yaml_str="$sites_parsed_yaml_str"
    memoized_dwt_sites_yaml_file="$hook_most_specific_dry_run_match"
  fi

  # Fetch only sites IDs (return early).
  case "$p_want" in 'ids_only')
    u_yaml_get_root_keys "$hook_most_specific_dry_run_match"
    dwt_sites_ids=("${yaml_keys[@]}")
    return
  esac

  case "$p_site" in

    # Deal with all sites.
    '*')
      eval "$sites_parsed_yaml_str"
      u_yaml_get_root_keys "$hook_most_specific_dry_run_match"
      dwt_sites_ids=("${yaml_keys[@]}")
      ;;

    # Deal with just one site (no point in getting site id in this case).
    *)
      local parsed_line
      local parsed_var
      local parsed_var_leaf
      while IFS= read -r parsed_line _; do
        parsed_var_leaf="=${parsed_line##*=}"
        parsed_var="${parsed_line%$parsed_var_leaf}"
        # Skip any line not matching prefix (by site).
        case "$parsed_line" in "${dwt_vars_prefix}${p_site}"*)
          eval "$parsed_line"
        esac
      done <<< "$sites_parsed_yaml_str"
      ;;

  esac
}

##
# Gets a single site data as an associative array (dictionary).
#
# This function writes its result to the following variable which MUST be preset
# in calling scope :
# @var dwt_site_data
#
# It will also attempt to use pre-existing dwt_sites_* variables if the site
# data was already loaded in current shell scope (i.e. avoids unnecessarily
# reloading sites.*.yml config files).
#
# @example
#   declare -A dwt_site_data
#   u_dwt_site_data 'my_site_id'
#   echo "site dir = ${dwt_site_data[dir]}"
#
u_dwt_site_data() {
  local p_site="$1"
  local var
  local key
  local sub_key
  local domain_specificity
  local conflicting_domain_specificity
  local var_isset
  local data_keys

  dwt_site_data=()
  u_dwt_sites_yml_keys
  data_keys="$dwt_sites_yml_keys"

  # Avoid unnecessarily reloading sites.*.yml config files.
  # Considers the "dir" key as mandatory (this is the entry used to check if
  # that site's config was loaded already in current shell scope).
  var="dwt_sites_${p_site}_dir"
  u_str_sanitize_var_name "$var" 'var'
  eval "var_isset=\"\${$var+set}\"" # <- Variables may be set to empty strings.
  if [[ -z "$var_isset" ]]; then
    u_dwt_sites "$p_site"
  fi

  # Add DB vars.
  u_db_vars_list
  for var in $db_vars_list; do
    var="db_$var"
    u_str_sanitize_var_name "$var" 'var'
    u_str_lowercase "$var" 'var'
    data_keys+=" $var"
  done

  # Assemble.
  for key in $data_keys; do
    var="dwt_sites_${p_site}_${key}"
    u_str_sanitize_var_name "$var" 'var'
    eval "var_isset=\"\${$var+set}\"" # <- Variables may be set to empty strings.
    if [[ -n "$var_isset" ]]; then
      dwt_site_data[$key]="${!var}"
    else

      # Special case for 'domain' : when it's not found in YAML settings, we
      # look for a 'domains' key and its sub-items that match by the following
      # variants. This allows to conditionally apply different domains while
      # sharing the rest of the settings.
      # TODO generalize to all keys (singular / plural).
      # TODO conflict tipping : introduce sub-level to specify weight (e.g. "dev.2").
      case "$key" in 'domain')
        key='domains'
        u_str_subsequences "$HOST_TYPE $INSTANCE_TYPE" '_'

        for sub_key in $str_subsequences; do
          var="dwt_sites_${p_site}_${key}_${sub_key}"
          u_str_sanitize_var_name "$var" 'var'
          # echo "$var = '${!var}'"
          eval "var_isset=\"\${$var+set}\""
          if [[ -n "$var_isset" ]]; then
            # In case of multiple matching variants, take the most specific.
            if [[ -n "${dwt_site_data[domain]}" ]]; then
              u_str_split1 'domain_specificity' "$sub_key" '_'
              u_str_split1 'conflicting_domain_specificity' "${dwt_site_data[_domain_sub_key]}" '_'
              # echo "  conflict : [${dwt_site_data[_domain_sub_key]}] ${dwt_site_data[domain]} <- [$sub_key] ${!var}"
              if [[ ${#domain_specificity[@]} -gt ${#conflicting_domain_specificity[@]} ]]; then
                dwt_site_data[domain]="${!var}"
                dwt_site_data[_domain_sub_key]="$sub_key"
                # echo "    1set _domain_sub_key to $sub_key (${!var})"
              fi
            else
              dwt_site_data[domain]="${!var}"
              dwt_site_data[_domain_sub_key]="$sub_key"
              # echo "    2set _domain_sub_key to $sub_key (${!var})"
            fi
          fi
        done
      esac
    fi
  done
}

##
# (Re)writes the multi-site config file (i.e. sites/sites.php).
#
# @requires the variables from u_dwt_sites() in calling scope :
# @var dwt_sites_ids
# @var dwt_sites_<SITE_ID>_*
#
# @param 1 [optional] String : base file to use. Gets copied before being
#   appended with the settings contents.
#   Defaults to "$SERVER_DOCROOT/sites/example.sites.php".
# @param 2 [optional] String : resulting file (output).
#   Defaults to "$SERVER_DOCROOT/sites/sites.php".
#
# @example
#   # Will use sites/example.sites.php as base, (re)writes sites/sites.php.
#   u_dwt_write_multisite_settings
#
#   # Customize base file
#   u_dwt_write_multisite_settings 'path/to/base/file'
#
#   # Customize resulting file.
#   u_dwt_write_multisite_settings '' "$SERVER_DOCROOT/sites/sites_local.php"
#
u_dwt_write_multisite_settings() {
  local base_file="$1"
  local target_file="$2"

  if [[ -z "$base_file" ]]; then
    base_file="$SERVER_DOCROOT/sites/example.sites.php"
  fi
  if [[ -z "$target_file" ]]; then
    target_file="$SERVER_DOCROOT/sites/sites.php"
  fi

  if [[ -f "$target_file" ]]; then
    rm -f "$target_file"
    if [[ $? -ne 0 ]]; then
      echo >&2
      echo "Error in u_dwt_write_multisite_settings() - $BASH_SOURCE line $LINENO: unable to remove the multisite settings file to recreate '$target_file'." >&2
      echo "-> Aborting (1)." >&2
      echo >&2
      exit 1
    fi
  fi

  if [[ -f "$base_file" ]]; then
    cp "$base_file" "$target_file"
    if [[ $? -ne 0 ]]; then
      echo >&2
      echo "Error in u_dwt_write_multisite_settings() - $BASH_SOURCE line $LINENO: unable to copy '$base_file' to '$target_file'." >&2
      echo "-> Aborting (2)." >&2
      echo >&2
      exit 2
    fi
    echo "" >> "$target_file"
  else
    echo '<?php' > "$target_file"
    echo "" >> "$target_file"
  fi

  echo "(Re)write the multi-site settings file (i.e. $target_file) ..."

  local var
  local site_id
  local site_dir
  local site_domain

  for site_id in "${dwt_sites_ids[@]}"; do
    # Sites' dir :
    var="dwt_sites_${site_id}_dir"
    u_str_sanitize_var_name "$var" 'var'
    site_dir="${!var}"
    # Sites' domain :
    var="dwt_sites_${site_id}_domain"
    u_str_sanitize_var_name "$var" 'var'
    site_domain="${!var}"
    if [[ -z "$site_domain" ]]; then
      site_domain="${site_id}.${INSTANCE_DOMAIN}"
    fi
    echo "\$sites['$site_domain'] = '$site_dir';" >> "$target_file"
  done

  echo "" >> "$target_file"

  echo "(Re)write the multi-site settings file (i.e. $target_file) : done."
  echo
}

##
# In a multi-site setup, given a singe site ID, returns writeable file paths.
#
# @param 1 String : the site ID.
# @param 2 [optional] String : wether or not to return the docker-compose
#   "aliases" of those vars. Any non-empty string can be passed. Defaults to
#   to an empty string, meaning : "I do not want the docker-compose version".
#   @see cwt/extensions/drupalwt_d4d/app/global.docker-compose.vars.sh
#
# This function writes its result to the following variable which MUST be preset
# in calling scope :
# @var dwt_sites_writeable_paths
#
# Allows to get per-site values for the following globals :
# - DRUPAL_FILES_DIR
# - DRUPAL_TMP_DIR
# - DRUPAL_TRANSLATION_DIR # Update : this does not appear to be supported in settings file declaration -> commented out for now
# - DRUPAL_CONFIG_SYNC_DIR
# - DRUPAL_PRIVATE_DIR
# @see cwt/extensions/drupalwt/app/global.vars.sh
#
# @example
#   # For local sites :
#   u_dwt_sites
#   for site_id in "${dwt_sites_ids[@]}"; do
#     u_str_sanitize_var_name "$site_id" 'site_id'
#     dwt_sites_writeable_paths=()
#     u_dwt_get_sites_writeable_paths "$site_id"
#     echo "Writeable_path for site '$site_id' :"
#     for writeable_path in "${dwt_sites_writeable_paths[@]}"; do
#       echo "  $writeable_path"
#     done
#   done
#
#   # For local sites, using the docker-compose version of the paths :
#   u_dwt_sites
#   for site_id in "${dwt_sites_ids[@]}"; do
#     u_str_sanitize_var_name "$site_id" 'site_id'
#     dwt_sites_writeable_paths=()
#     u_dwt_get_sites_writeable_paths "$site_id" 'dc'
#     echo "Writeable_path for site '$site_id' :"
#     for writeable_path in "${dwt_sites_writeable_paths[@]}"; do
#       echo "  $writeable_path"
#     done
#   done
#
#   # For remote sites - here, on the 'prod' remote instance :
#   dwt_remote_id='prod'
#   u_dwt_sites
#   for site_id in "${dwt_sites_ids[@]}"; do
#     u_str_sanitize_var_name "$site_id" 'site_id'
#     dwt_sites_writeable_paths=()
#     u_dwt_get_sites_writeable_paths "$site_id"
#     echo "Writeable_path for site '$site_id' :"
#     for writeable_path in "${dwt_sites_writeable_paths[@]}"; do
#       echo "  $writeable_path"
#     done
#   done
#
u_dwt_get_sites_writeable_paths() {
  local p_site="$1"
  local p_dc_variants="$2"

  # local path_names='files_dir tmp_dir translation_dir config_sync_dir private_dir'
  local path_names='files_dir tmp_dir config_sync_dir private_dir'
  local path_val=''
  local site_dir=''
  local v=''

  for path_name in $path_names; do

    # In a multi-site setup, all of these paths may be set in the YAML sites
    # declarations, e.g. : sites.local.yml or sites.prod.yml in project docroot.
    v="dwt_sites_${p_site}_${path_name}"
    path_val="${!v}"

    if [[ -n "$path_val" ]]; then
      if [[ -n "$p_dc_variants" ]]; then
        # In the YAML sites declaration, for paths like the config sync dir,
        # it contains the APP_DOCROOT (otherwise the ensure_dirs_exist.hook.sh
        # would not be possible).
        # @see cwt/extensions/drupalwt/app/ensure_dirs_exist.hook.sh
        # -> For docker-compose instances, we must convert it to a path relative
        # to APP_DOCROOT_C.
        # TODO limit this treatment to relative paths starting with APP_DOCROOT ?
        case "$path_name" in config_sync_dir)
          local to_remove="$APP_DOCROOT/"
          # echo "    to_remove = $to_remove (from path_val = $path_val)"
          path_val="${path_val/"$to_remove"/}"
          # echo "    -> result : path_val = $path_val"
        esac
      fi
      dwt_sites_writeable_paths+=("$path_val")
    else
      # In the absence of specific paths defined in sites' YAML files, fallback
      # to replace all 'sites/default' bits from the defaults.
      v="dwt_sites_${p_site}_dir"
      site_dir="${!v}"

      if [[ -z "$site_dir" ]]; then
        echo >&2
        echo "Error in $BASH_SOURCE line $LINENO: missing a site dir for '$p_site'." >&2
        echo "-> Aborting (1)." >&2
        echo >&2
        exit 1
      fi

      v="DRUPAL_${path_name}"
      if [[ -n "$p_dc_variants" ]]; then
        v="DRUPAL_${path_name}_C"
      fi
      u_str_uppercase "$v" 'v'
      path_val="${!v}"

      if [[ -n "$path_val" ]]; then
        # Drupal multi-site paths in the 'sites' dir all get the same treatment.
        # TODO exclude paths not matching 'sites/default/'.
        dwt_sites_writeable_paths+=(${path_val/'sites/default/'/"sites/$site_dir/"})
      fi
    fi
  done
}

##
# TODO [minor] use readonly global constant instead.
#
# Single source of truth : get the list of multi-site config file keys.
#
# This funtion writes its result to a variable subject to collision in calling
# scope :
# @var dwt_sites_yml_keys
#
# @example
#   u_dwt_sites_yml_keys
#   echo "$dwt_sites_yml_keys"
#
u_dwt_sites_yml_keys() {
  dwt_sites_yml_keys='domain dir install_profile config_sync_dir config_split'
}
