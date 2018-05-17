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
# TODO [wip] not finished - refacto in progress.
# @see u_instance_init()
#
# Write global (env) vars declarations to script file.
#
u_global_write() {
  echo "Writing global (env) vars to cwt/env/current/global.vars.sh ..."

  # First make sure we have something to write.
  if [ -z "$GLOBALS_COUNT" ]; then
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO: nothing to write." >&2
    echo "Aborting (1)." >&2
    echo >&2
    return 1
  elif [[ $P_VERBOSE == 1 ]]; then
    u_global_debug
  fi

  # (Re)init destination file (make empty).
  cat > cwt/env/current/global.vars.sh <<'EOF'
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
    u_str_split1 'evn_arr' "$global_name" '|'
    global_name="${evn_arr[1]}"
    eval "[[ -z \"\$$global_name\" ]] && echo \"readonly $global_name\"=\'\' >> cwt/env/current/global.vars.sh"
    eval "[[ -n \"\$$global_name\" ]] && echo \"readonly $global_name=\\\"\$$global_name\\\"\" >> cwt/env/current/global.vars.sh"
  done

  echo "Writing global (env) vars to cwt/env/current/global.vars.sh : done."
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
#   # - cwt/<CWT_SUBJECTS>/global.<PROVISION_USING>.vars.sh
#   # - cwt/extensions/<CWT_EXTENSIONS>/<EXT_SUBJECTS>/global.vars.sh
#   # - cwt/extensions/<CWT_EXTENSIONS>/<EXT_SUBJECTS>/global.<PROVISION_USING>.vars.sh
#   # - cwt/extensions/<CWT_EXTENSIONS>/global.vars.sh
#   # - cwt/extensions/<CWT_EXTENSIONS>/global.<PROVISION_USING>.vars.sh
#   # - $PROJECT_SCRIPTS/global.vars.sh
#   # - $PROJECT_SCRIPTS/global.<PROVISION_USING>.vars.sh
#   # -> Ex :
#   # - cwt/app/global.vars.sh
#   # - cwt/app/global.docker-compose.vars.sh
#   # - ...
#
u_global_lookup_paths() {
  local f
  local hook_dry_run_matches

  hook -a 'global' -c 'vars.sh' -v 'PROVISION_USING' -t

  for f in $hook_dry_run_matches; do
    global_lookup_paths+="$f "
  done

  # Allow extra lookup paths at the root of extensions.
  if [ -n "$CWT_EXTENSIONS" ]; then
    local extension
    for extension in $CWT_EXTENSIONS; do
      if [ -f "$extension/global.vars.sh" ]; then
        global_lookup_paths+="$extension/global.vars.sh "
      fi
    done
  fi

  # Allow extra lookup path at the root of project's scripts, *after* all
  # dynamic lookups above.
  if [ -f "$PROJECT_SCRIPTS/global.vars.sh" ]; then
    global_lookup_paths+="$PROJECT_SCRIPTS/global.vars.sh"
  fi
}

##
# Aggregates global env vars for this instance.
#
# @see u_instance_init()
# @see u_global_lookup_paths()
#
# @example
#   u_global_aggregate
#
u_global_aggregate() {
  local inc
  local global_lookup_paths=''

  u_global_lookup_paths

  for inc in $global_lookup_paths; do
    # Allow overrides for any "global.vars.sh" lookup path.
    u_autoload_override "$inc" 'continue'
    eval "$inc_override_evaled_code"

    . "$inc"
  done

  # Support deferred value assignation.
  # @see global()
  if [[ "${GLOBALS['.defer-max']}" -gt '0' ]]; then
    i=0
    max="${GLOBALS['.defer-max']}"
    for (( i=1; i<=$max; i++ )); do
      for global_name in ${GLOBALS[".defer-$i"]}; do
        u_global_assign_value "$global_name"
      done
    done
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
# @requires the following globals in calling scope :
# - $GLOBALS_INTERACTIVE
# - $GLOBALS
# - $P_MY_VAR_NAME (replacing 'MY_VAR_NAME' with the actual var name)
#
# @see global()
#
# @example
#   u_global_assign_value 'MY_VAR_NAME'
#
u_global_assign_value() {
  local p_var="$1"
  local multi_values=''

  u_str_sanitize_var_name "$p_var" 'p_var'

  eval "export $p_var"
  eval "unset $p_var"

  eval "local arg_val=\$P_${p_var}"
  local default_val="${GLOBALS[$p_var|default]}"

  if [[ -n "$arg_val" ]]; then
    eval "$p_var='$arg_val'"

  # Non-configurable vars.
  elif [[ "${GLOBALS[$p_var|no_prompt]}" == 1 ]]; then
    eval "$p_var='${GLOBALS[$p_var|value]}'"

  # List or "pile" of values (space-separated string).
  elif [[ -n "${GLOBALS[$p_var|values]}" ]]; then
    multi_values=$(u_string_trim "${GLOBALS[$p_var|values]}")
    eval "$p_var='$multi_values'"

  # Skippable default value assignment.
  elif [[ $GLOBALS_INTERACTIVE -eq 0 ]]; then
    echo
    if [[ -n "$default_val" ]]; then
      echo "Enter $p_var value,"
      eval "read -p \"or leave blank to use '$default_val' : \" $p_var"
    else
      eval "read -p \"Enter $p_var value : \" $p_var"
    fi
  fi

  # Assign default value fallback if the value is empty (e.g. may have been the
  # result of entering empty value in prompt).
  local empty_test=$(eval "echo \"\$$p_var\"")
  if [[ -z "$empty_test" ]] && [[ -n "$default_val" ]]; then
    eval "$p_var='$default_val'"
  fi

  # Once prompt has been made, prevent repeated calls for this var (recursion).
  # Except for 'append' vars (multiple values must pile-up on each call).
  # TODO [wip] confirm workaround edge case (multiple declarations must override
  # previous default value).
  if [[ $GLOBALS_INTERACTIVE -eq 0 ]]; then
    if [[ ${GLOBALS[$p_var|no_prompt]} -ne 1 ]] && [[ -z "$multi_values" ]]; then
      GLOBALS[$p_var|no_prompt]=1
      GLOBALS[$p_var|value]=$(eval "echo \"\$$p_var\"")
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
# @param 3 Integer : flag to prevent automatic export.
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
#   # - 'no_prompt'
#   # - 'append'
#   # - 'if-VAR_NAME'
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
global() {
  local p_var_name="$1"
  local p_values="$2"
  local p_prevent_export="$3"

  local index='0'

  u_str_sanitize_var_name "$p_var_name" 'p_var_name'

  # TODO sanitize $p_values.
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
          if-*|notif-*)
            local depending_var="${key:3}"
            local depending_value

            u_str_sanitize_var_name "$depending_var" 'depending_var'
            depending_value=$(eval "echo \"\$$depending_var\"")

            case "$key" in
              notif-*)
                if [[ "$depending_value" == "${declaration_arr[$key]}" ]]; then
                  return 0
                fi
              ;;
              if-*)
                if [[ "$depending_value" != "${declaration_arr[$key]}" ]]; then
                  return 0
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

  # These globals allow dynamic handling of args and default values.
  if ! u_in_array $p_var_name GLOBALS_UNIQUE_NAMES; then
    ((++GLOBALS_COUNT))
    GLOBALS_UNIQUE_NAMES+=($p_var_name)

    # This will be used to sort the array when complete.
    # See https://stackoverflow.com/a/39543809
    GLOBALS[".sorting"]+=" ${GLOBALS_COUNT}|${p_var_name} "
  fi

  # Provide control over value assignation order. Higher = later.
  if [[ "$index" -gt "${GLOBALS['.defer-max']}" ]]; then
    GLOBALS[".defer-max"]="$index"
  fi

  # Always defer global var declaration weighting more than 0 (default).
  # NB : the 1st declaration of multiple 'append' global() calls for the same
  # variable determines the index for all subsequent calls.
  if [[ "$index" -gt '0' ]]; then
    p_prevent_export='1'
    if ! u_in_array $p_var_name GLOBALS_DEFERRED; then
      GLOBALS_DEFERRED+=($p_var_name)
    fi
  # When previous declaration asked for deferred assignation, respect it even
  # in subsequent declarations not specifying an index.
  # TODO when the 1st declaration does not trigger deferred assignation and
  # subsequent calls do, workaround : "unexport" ?
  elif u_in_array $p_var_name GLOBALS_DEFERRED; then
    p_prevent_export='1'
  fi

  # Immediately attempt to export that variable unless explicitly prevented.
  # This allows conditional declarations in them (i.e. useful for settings that
  # need to adapt/react to each other).
  if [[ -z "$p_prevent_export" ]]; then
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
