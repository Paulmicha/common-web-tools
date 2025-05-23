#!/usr/bin/env bash

##
# GLobals-related utility functions.
#
# This file is sourced during core CWT bootstrap.
# @see cwt/bootstrap.sh
#
# Convention : functions names are all prefixed by "u" (for "utility").
#

##
# Gets the list of all globals variable names and their values.
#
# For performance reasons (to avoid using a subshell), this function writes its
# result to local variables subject to collision in calling scope :
#
# @var cwt_globals_var_names
# @var cwt_globals_values
#
# @example
#   # Print all var names :
#   u_global_list
#   for var_name in "${cwt_globals_var_names[@]}"; do
#     echo "$var_name"
#   done
#
#   # Print all values :
#   u_global_list
#   for value in "${cwt_globals_values[@]}"; do
#     echo "$value"
#   done
#
#   # Print both :
#   u_global_list
#   for i in "${!cwt_globals_var_names[@]}"; do
#     var_name="${cwt_globals_var_names[$i]}"
#     value="${cwt_globals_values[$i]}"
#     echo "$var_name = '$value'"
#   done
#
u_global_list() {
  cwt_globals_values=()
  cwt_globals_var_names=()

  # During instance init, the $GLOBALS associative array already exists.
  # Otherwise, we re-aggregate globals to get all supported variable names (in
  # "dry run" mode, cf. the GLOBALS_DRY_RUN switch).
  if [[ $GLOBALS_COUNT -eq 0 ]]; then
    declare -A GLOBALS
    GLOBALS_COUNT=0
    GLOBALS_UNIQUE_NAMES=()
    GLOBALS_UNIQUE_KEYS=()
    GLOBALS_DEFERRED=()
    GLOBALS['.defer-max']=0
    GLOBALS_DRY_RUN=1
    . cwt/env/global.vars.sh
    u_global_aggregate
  fi

  local global_var_name

  for global_var_name in "${GLOBALS_UNIQUE_NAMES[@]}"; do
    cwt_globals_var_names+=("$global_var_name")
    cwt_globals_values+=("${!global_var_name}")
  done
}

##
# Writes global vars readonly declarations for current instance.
#
# Resulting generated files (git-ignored) :
#   - .env
#   - scripts/cwt/local/global.vars.sh
#
# @see u_instance_init()
#
u_global_write() {
  local gn_arr=()
  local global_val=''
  local has_double_quote=0
  local has_single_quote=0

  # Update : global vars related to DB must *not* be readonly in order to
  # simplify manipulations targeting several DBs on the same stack.
  local readonly
  local v
  local db_id
  local db_var
  local prefixed_db_var

  if [ -z "$GLOBALS_COUNT" ]; then
    echo >&2
    echo "Error in u_global_write() - $BASH_SOURCE line $LINENO: nothing to write." >&2
    echo "Aborting (1)." >&2
    echo >&2
    return 1
  fi

  echo "Writing global (env) vars to scripts/cwt/local/global.vars.sh ..."

  # (Re)init destination files (make empty).
  echo -n '' > .env
  cat > scripts/cwt/local/global.vars.sh <<'EOF'
#!/usr/bin/env bash

##
# Current instance global (env) vars declarations.
#
# This file is automatically generated during "instance init", and it will be
# entirely overwritten every time it is executed.
#
# @see u_instance_init() in cwt/instance/instance.inc.sh
# @see u_global_write() in cwt/utilities/global.sh
#

EOF

  # Write every aggregated globals.
  for global_name in ${GLOBALS['.sorting']}; do
    u_str_split1 'gn_arr' "$global_name" '|'

    global_name="${gn_arr[1]}"
    global_val="${!global_name}"

    has_double_quote=0
    has_single_quote=0

    case "$global_val" in *'"'*)
      has_double_quote=1
    esac

    case "$global_val" in *"'"*)
      has_single_quote=1
    esac

    # TODO is there a way out of this ? Considered edge case, #YAGNI.
    if [[ $has_double_quote == 1 && $has_single_quote == 1 ]]; then
      echo
      echo "Notice : the global $global_name has the following value :"
      echo "  ${!global_name}"
      echo "  -> it appears to have both single quotes and double quotes, which can cause unexpected issues."
      echo
    fi

    # Update : global vars related to DB must not be readonly in order to
    # simplify manipulations targeting several DBs on the same stack.
    readonly='readonly '
    db_vars_list=''
    v=''

    if [[ -n "$CWT_DB_IDS" ]]; then
      u_db_vars_list

      for v in $db_vars_list; do
        db_var="DB_$v"

        for db_id in $CWT_DB_IDS; do
          prefixed_db_var="${db_id}_${db_var}"
          u_str_uppercase "$prefixed_db_var" 'prefixed_db_var'

          # Debug.
          # echo "$global_name = $db_var or $prefixed_db_var ?"

          case "$global_name" in "$db_var"|"$prefixed_db_var")
            readonly=''
          esac
        done
      done
    fi

    # Debug.
    # echo "readonly = '$readonly'"

    if [[ -z "$global_val" ]]; then
      echo "${readonly}$global_name=''" >> scripts/cwt/local/global.vars.sh
    else
      if [[ $has_single_quote != 1 ]]; then
        echo "${readonly}$global_name='$global_val'" >> scripts/cwt/local/global.vars.sh
      else
        # TODO do we want to escape any '$' sign when using double quotes ?
        echo "${readonly}$global_name=\"$global_val\"" >> scripts/cwt/local/global.vars.sh
      fi
    fi

    # Also write globals to git-ignored '.env' file for Makefile and other tools
    # like docker-compose.
    # In this case, any value that could break inclusion of the .env file in a
    # bash script must be quoted.
    case "$global_val" in *' '*|*'$'*|*'#'*|*'['*|*']'*|*'*|*'*|*'&'*|*'*'*|*'"'*|*"'"*)
      if [[ $has_single_quote != 1 ]]; then
        global_val="'$global_val'"
      else
        global_val="\"$global_val\""
      fi
    esac

    if [[ -z "$global_val" ]]; then
      echo "$global_name=" >> .env
    else
      echo "$global_name=$global_val" >> .env
    fi
  done

  echo "Writing global (env) vars to scripts/cwt/local/global.vars.sh : done."
  echo
}

##
# Buils the lookup path list for global env vars declarations.
#
# This produces lookup paths by subject, action, and extensions.
#
# NB : this function writes its result to a variable subject to collision in
# calling scope.
#
# @var global_lookup_paths
#
# @see u_instance_init()
# @see u_global_aggregate()
#
# @example
#   global_lookup_paths=''
#   u_global_lookup_paths
#   echo "$global_lookup_paths" # <- Yields the following lookup paths :
#   # - cwt/<CWT_SUBJECTS>/global.vars.sh
#   # - cwt/extensions/<CWT_EXTENSIONS>/<EXT_SUBJECTS>/global.vars.sh
#   # - cwt/extensions/<CWT_EXTENSIONS>/global.vars.sh
#   # - scripts/global.vars.sh
#   # - cwt/<CWT_SUBJECTS>/global.<PROVISION_USING>.vars.sh
#   # - cwt/extensions/<CWT_EXTENSIONS>/<EXT_SUBJECTS>/global.<PROVISION_USING>.vars.sh
#   # - cwt/extensions/<CWT_EXTENSIONS>/global.<PROVISION_USING>.vars.sh
#   # - scripts/global.<PROVISION_USING>.vars.sh
#   # -> Ex :
#   # - cwt/app/global.vars.sh
#   # - cwt/app/global.docker-compose.vars.sh
#   # - ...
#
u_global_lookup_paths() {
  local f
  local hook_dry_run_matches

  # 1. Files named without variant (i.e. 'global.vars.sh')
  hook_dry_run_matches=''
  hook -a 'global' -c 'vars.sh' -t
  for f in $hook_dry_run_matches; do
    global_lookup_paths+="$f "
  done
  # ... including extra lookup paths at the root of extensions' folders.
  if [ -n "$CWT_EXTENSIONS" ]; then
    local extension
    for extension in $CWT_EXTENSIONS; do
      ext_path=''
      u_cwt_extension_path "$extension"
      if [ -f "$ext_path/$extension/global.vars.sh" ]; then
        global_lookup_paths+="$ext_path/$extension/global.vars.sh "
      fi
    done
  fi

  # 2. Files using variant in their name (i.e. 'global.docker-compose.vars.sh')
  hook_dry_run_matches=''
  hook -a 'global' -c "${PROVISION_USING}.vars.sh" -t
  for f in $hook_dry_run_matches; do
    global_lookup_paths+="$f "
  done
  # ... including extra lookup paths at the root of extensions' folders.
  if [ -n "$CWT_EXTENSIONS" ]; then
    local extension
    for extension in $CWT_EXTENSIONS; do
      ext_path=''
      u_cwt_extension_path "$extension"
      if [ -f "$ext_path/$extension/global.${PROVISION_USING}.vars.sh" ]; then
        global_lookup_paths+="$ext_path/$extension/global.${PROVISION_USING}.vars.sh "
      fi
    done
  fi
}

##
# Aggregates all global env vars and assigns their value(s).
#
# This function can be called in different contexts :
#   1. generating globals for the first time
#   2. updating previously generated globals
#   3. get the list of all globals (dynamically)
#
# When it's 3. we need to also read the custom Yaml declarations. It's already
# loaded in calling scope for the other 2 cases.
#
# It manipulates or reads the following vars from calling scope :
#
# @var yaml_parsed_sp_init
# @var yaml_parsed_globals
# @var globals_skip_yaml
#
# @see u_instance_init()
# @see u_global_list()
# @see u_global_lookup_paths()
# @see global()
# @see u_instance_yaml_config_load()
#
u_global_aggregate() {
  local inc
  local global_lookup_paths=''

  # The context 3. (get the list of all globals) requires adding the custom Yaml
  # declarations.
  if [[ -z "$yaml_parsed_globals" ]]; then
    yaml_parsed_sp_init=''
    yaml_parsed_globals=''
    u_instance_yaml_config_load
    if [[ -n "$yaml_parsed_globals" ]]; then
      eval "$yaml_parsed_globals"
    fi
  fi

  # Flag to alter the default global() process in order to get YAML precedence.
  globals_skip_yaml=1

  u_global_lookup_paths

  for inc in $global_lookup_paths; do
    # Allow overrides for any "global.vars.sh" lookup path.
    u_autoload_override "$inc" 'continue'
    eval "$inc_override_evaled_code"

    . "$inc"
  done

  # Support deferred value assignment.
  # @see global()
  if [[ ${GLOBALS['.defer-max']} -gt 0 ]]; then
    i=0
    max=${GLOBALS['.defer-max']}
    for (( i=1; i<=$max; i++ )); do
      for global_name in ${GLOBALS[".defer-$i"]}; do

        # Debug
        # echo
        # echo "  ! level $i Deferred assign_value for $global_name (currently = '${!global_name}')"

        u_global_assign_value "$global_name"
      done
    done

    # Debug
    # echo
  fi
}

##
# Executes given callback function for all env vars discovered so far.
#
# @requires the following globals in calling scope :
# - $GLOBALS
# - $GLOBALS_UNIQUE_NAMES
#
# @see u_global_aggregate()
#
# @example
#   u_global_foreach u_global_assign_value
#
u_global_foreach() {
  local p_callback="$1"
  local globals_arr
  local global_name

  for global_name in ${GLOBALS['.sorting']}; do
    u_str_split1 'globals_arr' "$global_name" '|'
    global_name="${globals_arr[1]}"
    $p_callback $global_name
  done
}

##
# Assigns arg or default value to given global env var.
#
# Unless "-y" flag is used in instance init call, this will also prompt for
# user input (terminal) before using default value fallback.
#
# @param 1 String : global variable name.
#
# @requires or uses the following globals in calling scope :
# - $GLOBALS
# - $GLOBALS_DRY_RUN
# - $p_cwtii_yes
# - $p_cwtii_my_var_name (replacing 'MY_VAR_NAME' with the actual var name)
# - $test_cwt_global_aggregate
#
# @see global()
#
# @example
#   u_global_assign_value 'MY_VAR_NAME'
#
u_global_assign_value() {
  local p_var="$1"
  local multi_values=''

  if [[ $GLOBALS_DRY_RUN -eq 1 ]]; then
    return
  fi

  u_str_sanitize_var_name "$p_var" 'p_var'

  # Debug.
  # echo "    u_global_assign_value() $p_var"

  # Support tests.
  # @see cwt/test/cwt/global.test.sh
  if [[ $test_cwt_global_aggregate -ne 1 ]]; then
    eval "unset $p_var"
  fi

  # Any arguments passed to u_instance_init() take precedence.
  local arg_var_name="p_cwtii_$p_var"
  u_str_lowercase "$arg_var_name" 'arg_var_name'
  local arg_val="${!arg_var_name}"

  local default_val="${GLOBALS[$p_var|default]}"

  # Conditions should also apply for deferred assignments. In fact, it's when
  # they're most useful because it ensures depending vars are already assigned.
  if [[ -n "${GLOBALS[$p_var|condition]}" ]]; then
    local depending_var="${GLOBALS[$p_var|depending_var]}"
    local depending_value="${!depending_var}"
    local depending_match="${GLOBALS[$p_var|depending_match]}"

    # For each condition type, deal with true/false fallback values. If none are
    # set and the condition doesn't match, we return early (no assignment).
    case "${GLOBALS[$p_var|condition]}" in
      'ifnot')
        if [[ "$depending_value" == "$depending_match" ]]; then
          if [[ -n "${GLOBALS[$p_var|value_if_false]}" ]]; then
            default_val="${GLOBALS[$p_var|value_if_false]}"

            # Debug.
            # echo "    $p_var = '$default_val' // Set default_val to conditional value if false."
          else

            # Debug.
            # echo "    $p_var : no assignment for condition ${GLOBALS[$p_var|condition]} (depending_value = '$depending_value', depending_match = '$depending_match')"

            return
          fi
        elif [[ -n "${GLOBALS[$p_var|value_if_true]}" ]]; then
          default_val="${GLOBALS[$p_var|value_if_true]}"

            # Debug.
            # echo "    $p_var = '$default_val' // Set default_val to conditional value if true."
        fi
        ;;
      'if')
        if [[ "$depending_value" != "$depending_match" ]]; then
          if [[ -n "${GLOBALS[$p_var|value_if_false]}" ]]; then
            default_val="${GLOBALS[$p_var|value_if_false]}"

            # Debug.
            # echo "    $p_var = '$default_val' // Set default_val to conditional value if false."
          else

            # Debug.
            # echo "    $p_var : no assignment for condition ${GLOBALS[$p_var|condition]} (depending_value = '$depending_value', depending_match = '$depending_match')"

            return
          fi
        elif [[ -n "${GLOBALS[$p_var|value_if_true]}" ]]; then
          default_val="${GLOBALS[$p_var|value_if_true]}"

            # Debug.
            # echo "    $p_var = '$default_val' // Set default_val to conditional value if true."
        fi
        ;;
    esac
  fi

  if [[ -n "$arg_val" ]]; then
    printf -v "$p_var" '%s' "$arg_val"

    # Debug.
    # echo "    $p_var = '$arg_val' // Value directly passed by argument or YAML config file."

  # Non-configurable vars.
  elif [[ "${GLOBALS[$p_var|no_prompt]}" == 1 ]]; then
    printf -v "$p_var" '%s' "${GLOBALS[$p_var|value]}"

    # Debug.
    # echo "    $p_var = '${GLOBALS[$p_var|value]}' // Non-configurable var."

  # List or "pile" of values (space-separated string).
  elif [[ -n "${GLOBALS[$p_var|values]}" ]] && [[ $test_cwt_global_aggregate -ne 1 ]]; then
    multi_values="${GLOBALS[$p_var|values]}"
    printf -v "$p_var" '%s' "$multi_values"

    # Debug.
    # echo "    $p_var = '$multi_values' // 'Append' type list (space-separated string)."

  # Skippable terminal prompts for manual user input ('-y' flag to disable).
  elif [[ $p_cwtii_yes -eq 0 ]]; then
    echo
    echo "Initializing $p_var value :"

    if [[ -n "${GLOBALS[$p_var|help]}" ]]; then
      echo "${GLOBALS[$p_var|help]}"
    fi

    if [[ -n "$default_val" ]]; then
      eval "read -p \"-> Enter $p_var value. Leave blank to use the default value '$default_val' : \" $p_var"
    else
      eval "read -p \"-> Enter $p_var value : \" $p_var"
    fi
  fi

  # Assign default value fallback if the value is empty (e.g. may have been the
  # result of entering empty value in prompt).
  local empty_test="${!p_var}"
  if [[ -z "$empty_test" ]]; then

    # If the same global is encountered more than once, then it can mean the
    # deferred assignment is requested to replace the value (or append more
    # values to it).
    if [[ -z "$multi_values" ]] && [[ -n "${GLOBALS[$p_var|value]}" ]]; then
      printf -v "$p_var" '%s' "${GLOBALS[$p_var|value]}"

      # Debug.
      # echo "    $p_var = '${GLOBALS[$p_var|value]}' // Deferred manual value assignment."

    elif [[ -n "$default_val" ]]; then
      printf -v "$p_var" '%s' "$default_val"

      # Debug.
      # echo "    $p_var = '$default_val' // Assign default value fallback because the value is empty."
    fi
  fi

  # Once prompt has been made, prevent repeated calls for this var (recursion).
  # Except for 'append' vars (multiple values must pile-up on each call).
  if [[ $p_cwtii_yes -eq 0 ]]; then
    if [[ ${GLOBALS[$p_var|no_prompt]} -ne 1 ]] && [[ -z "$multi_values" ]]; then
      GLOBALS[$p_var|no_prompt]=1
      GLOBALS[$p_var|value]="${!p_var}"
    fi
  fi
}

##
# Adds new variable in $GLOBALS.
#
# Increments a shared counter to maintain order, because some variables may depend
# on each other.
#
# @param 1 String : global variable name.
# @param 2 [optional] String : non-configurable value or key/value syntax (see
#   examples below)
# @param 3 Integer : flag to prevent immediate value assignment.
#
# @requires the following globals in calling scope (main shell) :
# - $GLOBALS
# - $GLOBALS_COUNT
# - $GLOBALS_UNIQUE_NAMES
# - $GLOBALS_UNIQUE_KEYS
#
# @see u_global_assign_value()
#
# For better readability in env includes files, we exceptionally name that
# function without following the usual convention.
#
# @examples (write)
#   global MY_VAR_NAME
#   global MY_VAR_NAME "Simple string declaration (non-configurable / no prompt to customize during init)"
#   global MY_VAR_NAME2 "[default]=test"
#
#   # Custom keys may be used, provided they don't clash with the following keys
#   # already used internally by CWT :
#   # - 'default'
#   # - 'value'
#   # - 'values'
#   # - 'append'
#   # - 'if-VAR_NAME'
#   # - 'ifnot-VAR_NAME'
#   # - 'no_prompt'
#   # - 'index'
#   global MY_VAR_NAME3 "[key]=value [key2]='value 2' [key3]='$(my_callback_function)'"
#
# @examples (append)
#   # Notice there cannot be any space inside each value.
#   global MY_MULTI_VALUE_VAR "[append]=multiple"
#   global MY_MULTI_VALUE_VAR "[append]=declarations"
#   global MY_MULTI_VALUE_VAR "[append]=will-be"
#   global MY_MULTI_VALUE_VAR "[append]=appended/to"
#   global MY_MULTI_VALUE_VAR "[append]=a_SPACE_separated_string"
#   # Example read :
#   for val in $MY_MULTI_VALUE_VAR; do
#     echo "MY_MULTI_VALUE_VAR value : $val"
#   done
#
# @examples (condition)
#   global MY_VAR "hello value"
#   global MY_COND_VAR_NOMATCH "[if-MY_VAR]=test [default]=foo"
#   global MY_COND_VAR_MATCH "[if-MY_VAR]='hello value' [default]=bar"
#   # To verify (should only output MY_COND_VAR_MATCH) :
#   u_global_foreach u_global_assign_value
#   u_global_debug
#
# @example (read)
#   u_global_debug
#
# @example (deferred assignment)
#   # This is used so that globals may depend on others declared or
#   # overridden in other includes. It functions like CSS z-index : higher
#   # values get assigned later. It eliminates the need to control aggregation
#   # order : instead, it guarantees the order of values assignment.
#   global ANOTHER_VAR 'test'
#   global MY_DEFERRED_VAR "[index]=1 [if-ANOTHER_VAR]=test [value]='my value'"
#   global MY_DEFERRED_VAR_2 "[index]=2 [value]='${MY_DEFERRED_VAR} can be used here without worrying if it was already assigned or not.'"
#
global() {
  local p_var_name="$1"
  local p_values="$2"
  local p_prevent_assignment="$3"

  local index='0'

  u_str_sanitize_var_name "$p_var_name" 'p_var_name'

  # Skip any var that was already set in YAML files.
  # @see u_global_aggregate()
  if [[ -n "$yaml_parsed_globals" ]] && [[ $globals_skip_yaml -eq 1 ]]; then
    case "$yaml_parsed_globals" in *"global ${p_var_name} "*)
      return
    esac
  fi

  # TODO [evol] sanitize $p_values ?
  if [[ -n "$p_values" ]]; then

    # If the value does not begin with '[', assume the var non-configurable.
    if [[ "${p_values:0:1}" != '[' ]]; then
      GLOBALS["${p_var_name}|value"]="$p_values"
      GLOBALS["${p_var_name}|no_prompt"]=1

    # Key/value store system.
    else
      local key
      local declaration_arr

      # Transform input string to associative array.
      eval "declare -A declaration_arr=( $p_values )"

      for key in "${!declaration_arr[@]}"; do
        u_array_add_once "$key" GLOBALS_UNIQUE_KEYS

        case "$key" in

          # Controls the order of assignment. Higher values defer later.
          index)
            index="${declaration_arr[$key]}"
          ;;

          # Handles conditional declarations. Prevents declaring the variable
          # altogether if the depending variable's value does not match the one
          # provided (matching using operator provided as a prefix).
          if-*|ifnot-*)
            local depending_var
            local depending_var_split_arr
            local depending_value

            u_str_split1 'depending_var_split_arr' "$key" '-'
            depending_var="${depending_var_split_arr[1]}"

            u_str_sanitize_var_name "$depending_var" 'depending_var'
            depending_value="${!depending_var}"

            # Needed for deferred assignments.
            # @see u_global_assign_value()
            GLOBALS["$p_var_name|depending_var"]="$depending_var"
            GLOBALS["$p_var_name|depending_match"]="${declaration_arr[$key]}"
            GLOBALS["$p_var_name|value_if_true"]="${declaration_arr[true]}"
            GLOBALS["$p_var_name|value_if_false"]="${declaration_arr[false]}"

            case "$key" in
              ifnot-*)
                GLOBALS["$p_var_name|condition"]='ifnot'

                # Debug.
                # echo "$p_var_name ifnot : $depending_value == ${declaration_arr[$key]} ?"

                if [[ "$depending_value" == "${declaration_arr[$key]}" ]]; then
                  # Debug.
                  # echo "  -> yes (abort)"
                  # echo "  default = ${GLOBALS[$p_var_name|default]}"

                  # return 0
                  p_prevent_assignment='1'

                  # debug
                  # echo "$p_var_name prevented because condition ifnot does not match"
                fi
              ;;
              if-*)
                GLOBALS["$p_var_name|condition"]='if'

                # Debug.
                # echo "$p_var_name if : $depending_value != ${declaration_arr[$key]} ?"

                if [[ "$depending_value" != "${declaration_arr[$key]}" ]]; then
                  # Debug.
                  # echo "  -> yes (abort)"
                  # echo "  default = ${GLOBALS[$p_var_name|default]}"

                  # return 0
                  p_prevent_assignment='1'

                  # debug
                  # echo "$p_var_name prevented because condition if does not match"
                fi
              ;;
            esac
          ;;

          # Appends multiple values to the same var. Allow globals to be
          # declared multiple times to add values (space-separated string).
          append)
            # Ability to scope values in different "piles" using the 'to' key.
            # Defaults to 'values'.
            local append_to='values'

            if [[ -n "${declaration_arr[to]}" ]]; then
              append_to="${declaration_arr[to]}"
            fi

            if [[ -n "${GLOBALS[$p_var_name|values]}" ]]; then
              GLOBALS["${p_var_name}|$append_to"]+=" ${declaration_arr[$key]}"
            else
              GLOBALS["${p_var_name}|$append_to"]="${declaration_arr[$key]}"
            fi
          ;;

          # For 'append' using the 'to' key, we need to easily fetch all "piles"
          # (all values that were used in 'to').
          to)
            if [[ -n "${GLOBALS[$p_var_name|tos]}" ]]; then
              GLOBALS["${p_var_name}|tos"]+=" ${declaration_arr[$key]}"
            else
              GLOBALS["${p_var_name}|tos"]="${declaration_arr[$key]}"
            fi
          ;;

          # Default.
          *)
            GLOBALS["${p_var_name}|${key}"]="${declaration_arr[$key]}"
          ;;
        esac
      done
    fi
  fi

  # Prevent conditional assignment (and the rest of the processing below if no
  # match was found above) if the global using a condition does not require
  # deferred assignment.
  # For conditional global values requiring default value(s), they MUST use the
  # deferred assignment. Ex :
  # global SERVER_DOCROOT_C "[if-SERVER_DOCROOT]='$APP_DOCROOT/docroot' [true]=/var/www/html/docroot [false]=/var/www/html/web [index]=1"
  if [[ ! $index -gt 0 ]] && [[ -n "${GLOBALS[$p_var_name|condition]}" ]]; then
    unset GLOBALS["$p_var_name|condition"]
    if [[ -n "$p_prevent_assignment" ]]; then
      return 0
    fi
  fi

  # Because it's possible to call global() several times for the same variable
  # (e.g. to append values to a list), and because the declaration order may
  # matter, we need to keep a list (and count) of unique variable names.
  if ! u_in_array $p_var_name GLOBALS_UNIQUE_NAMES; then
    ((++GLOBALS_COUNT))
    GLOBALS_UNIQUE_NAMES+=($p_var_name)

    # This will be used to sort the array when complete.
    # See https://stackoverflow.com/a/39543809
    GLOBALS[".sorting"]+=" ${GLOBALS_COUNT}|${p_var_name} "
  fi

  # Provide control over value assignation order. Higher = later.
  if [[ $index -gt ${GLOBALS['.defer-max']} ]]; then
    GLOBALS['.defer-max']=$index
  fi

  # Always defer global var declaration weighting more than 0 (default).
  # NB : the 1st declaration of multiple 'append' global() calls for the same
  # variable determines the index for all subsequent calls.
  if [[ $index -gt 0 ]]; then
    p_prevent_assignment='1'

    # debug
    # echo "$p_var_name prevented because deferred index = $index"

    if ! u_in_array $p_var_name GLOBALS_DEFERRED; then
      GLOBALS_DEFERRED+=($p_var_name)
    fi
  # When previous declaration asked for deferred assignation, respect it even
  # in subsequent declarations not specifying an index.
  # TODO when the 1st declaration does not trigger deferred assignation and
  # subsequent calls do, workaround : "unexport" ?
  elif u_in_array $p_var_name GLOBALS_DEFERRED; then

    # debug
    # echo "$p_var_name prevented because previously put in GLOBALS_DEFERRED : '$GLOBALS_DEFERRED'"

    p_prevent_assignment='1'
  fi

  # Immediately attempt to export that variable unless explicitly prevented.
  # This allows conditional declarations in them (i.e. useful for settings that
  # need to adapt/react to each other).
  if [[ -z "$p_prevent_assignment" ]]; then
    u_global_assign_value "$p_var_name"

  # When global var declaration is deferred, append to 1 list per index.
  # @see cwt/stack/init/aggregate_env_vars.sh
  elif [[ "$index" -gt '0' ]]; then
    # We only need 1 assignation -> skip if already in list.
    case "${GLOBALS[.defer-$index]}" in
      *"${p_var_name}"*) return ;;
    esac
    GLOBALS[".defer-$index"]+=" ${p_var_name} "
  fi
}

##
# [debug] Prints current environment globals and their associated data.
#
# @see global()
#
u_global_debug() {
  local global_name
  local globals_arr
  local key
  local val

  echo
  echo "Defined globals :"
  echo

  for global_name in ${GLOBALS['.sorting']}; do
    u_str_split1 'globals_arr' "$global_name" '|'
    global_name="${globals_arr[1]}"

    eval "[[ -z \"\$$global_name\" ]] && echo \"$global_name\" \(empty\)";
    eval "[[ -n \"\$$global_name\" ]] && echo \"$global_name = \$$global_name\"";

    for key in ${GLOBALS_UNIQUE_KEYS[@]}; do
      val="${GLOBALS[$global_name|$key]}"
      if [[ -n "$val" ]]; then
        echo "  - ${key} = ${GLOBALS[${global_name}|${key}]}";
      fi
    done
  done

  echo
}
