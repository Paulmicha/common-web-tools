#!/usr/bin/env bash

##
# Hooks-related utility functions.
#
# This file is sourced during core CWT bootstrap.
# @see cwt/bootstrap.sh
#
# Convention : functions names are all prefixed by "u" (for "utility").
#

##
# Triggers an "event" optionally filtered by primitives.
#
# Arguments are all optional, but this function requires at least either
# 1 action (-a) OR 1 extension (-e). See explanations below.
#
# In order to "listen" to events, some specific file(s) must use the exact path
# and name corresponding to its arguments. For a detailed list of expected
# output given various inputs :
# @see cwt/test/cwt/hook.test.sh
#
# Primitives are fundamental values dynamically generated during bootstrap :
# @see cwt/bootstrap.sh
# @see u_cwt_extend()
#
# Calling this function will source all file includes matched by subject,
# action, prefix, variant, and extension. Every extension defines a base path from
# which additional lookup paths are derived (as well as a corresponding namespace
# for glabals containing their primitives).
#
# Important notes about the 'variants' (-v) argument :
# If this function gets called without any 'variant' filter(s), it will
# automatically look for suggestions using INSTANCE_TYPE.
# Variants are combinatory. Each variant value must be an existing glabal var
# which will generate the following lookup paths given the call :
# $ hook -a 'my_action' -s 'my_subject' -v 'PROVISION_USING INSTANCE_TYPE'
# + the values PROVISION_USING='docker-compose' and INSTANCE_TYPE='dev' :
# - cwt/my_subject/my_action.hook.sh
# - cwt/my_subject/my_action.docker-compose.hook.sh
# - cwt/my_subject/my_action.docker-compose.dev.hook.sh
# - cwt/my_subject/my_action.dev.hook.sh
#
# @requires the following global variables in calling scope :
# - CWT_ACTIONS
# - CWT_SUBJECTS
# - CWT_EXTENSIONS
#
# @uses the following global variables in calling scope if they exist :
# - ${EXTENSION_NAMESPACE}_ACTIONS
# - ${EXTENSION_NAMESPACE}_SUBJECTS
#
# NB : the default separator used to concatenate parts in file names is
# the underscore '_', except for variants which use dot '.'.
# Dashes '-' are reserved for folder names and to separate "semver" suffixes.
# Semver suffixes can be used in extension folder names and variant values.
#
# Also note that each argument accepts several values by using a space to
# separate them. E.g. :
# $ hook -a 'start' -s 'stack service instance app'
#
# TODO Document cache warmup.
#
# @examples
#
#   # 1. When providing a single action :
#   hook -a 'bootstrap'
#   # Yields the following lookup paths (ALL includes found are sourced) :
#   # (given INSTANCE_TYPE='prod')
#   # - cwt/<CWT_SUBJECTS>/bootstrap.hook.sh
#   # - cwt/<CWT_SUBJECTS>/bootstrap.prod.hook.sh
#   # - cwt/extensions/<CWT_EXTENSIONS>/<EXT_SUBJECTS>/bootstrap.hook.sh
#   # - cwt/extensions/<CWT_EXTENSIONS>/<EXT_SUBJECTS>/bootstrap.prod.hook.sh
#
#   # 2. When providing an action + a filter by subject :
#   hook -a 'init' -s 'stack'
#   # Yields the following lookup paths (ALL includes found are sourced) :
#   # (given INSTANCE_TYPE='prod')
#   # - cwt/stack/init.hook.sh
#   # - cwt/stack/init.prod.hook.sh
#   # - cwt/extensions/<CWT_EXTENSIONS>/stack/init.hook.sh
#   # - cwt/extensions/<CWT_EXTENSIONS>/stack/init.prod.hook.sh
#
#   # 3. When providing an action + a filter by 1 or several subjects + 1 or
#   #   several variants filter :
#   hook -a 'init' -s 'stack' -v 'HOST_TYPE INSTANCE_TYPE'
#   # Yields the following lookup paths (ALL includes found are sourced) :
#   # (given INSTANCE_TYPE='dev' and HOST_TYPE='local')
#   # - cwt/stack/init.hook.sh
#   # - cwt/stack/init.local.hook.sh
#   # - cwt/stack/init.local.dev.hook.sh
#   # - cwt/stack/init.dev.hook.sh
#   # - cwt/extensions/<CWT_EXTENSIONS>/stack/init.hook.sh
#   # - cwt/extensions/<CWT_EXTENSIONS>/stack/init.local.hook.sh
#   # - cwt/extensions/<CWT_EXTENSIONS>/stack/init.local.dev.hook.sh
#   # - cwt/extensions/<CWT_EXTENSIONS>/stack/init.dev.hook.sh
#
#   # 4. Extensions filter :
#   hook -e 'nodejs'
#   # Yields the following lookup paths (ALL includes found are sourced) :
#   # (given INSTANCE_TYPE='prod')
#   # - scripts/extensions/nodejs/<EXT_SUBJECTS>/<SUBJECT_ACTIONS>.prod.hook.sh
#
#   # 5. Prefixes filter are exclusive by default, which means pure actions are
#   #   not included. Ex :
#   hook -a 'bootstrap' -p 'pre'
#   # Yields the following lookup paths (ALL includes found are sourced) :
#   # (given INSTANCE_TYPE='prod')
#   # - cwt/<CWT_SUBJECTS>/pre_bootstrap.hook.sh
#   # - cwt/<CWT_SUBJECTS>/pre_bootstrap.prod.hook.sh
#   # - cwt/extensions/<CWT_EXTENSIONS>/<EXT_SUBJECTS>/pre_bootstrap.hook.sh
#   # - cwt/extensions/<CWT_EXTENSIONS>/<EXT_SUBJECTS>/pre_bootstrap.prod.hook.sh
#
#   # 6. Project root dir additional lookup :
#   hook -s 'instance' -a 'env' -c 'yml' -v 'HOST_TYPE INSTANCE_TYPE' -t -r
#   # Yields the following lookup paths (not sourcing matches because -t flag) :
#   # (given HOST_TYPE='local' and INSTANCE_TYPE='dev')
#   # - cwt/instance/env.yml
#   # - cwt/instance/cwt.local.yml
#   # - cwt/instance/cwt.local.dev.yml
#   # - cwt/instance/cwt.dev.yml
#   # - cwt/extensions/<CWT_EXTENSIONS>/instance/env.yml
#   # - cwt/extensions/<CWT_EXTENSIONS>/instance/cwt.local.yml
#   # - cwt/extensions/<CWT_EXTENSIONS>/instance/cwt.local.dev.yml
#   # - cwt/extensions/<CWT_EXTENSIONS>/instance/cwt.dev.yml
#   # - env.yml
#   # - cwt.local.yml
#   # - cwt.local.dev.yml
#   # - cwt.dev.yml
#
# We exceptionally name that function without following the usual convention.
#
hook() {
  # Update 2024-06 cache results.
  local p_cache_key="$@"
  local regex="-v ([^\-]+)"

  if [[ $p_cache_key =~ $regex ]]; then
    for var in ${BASH_REMATCH[1]}; do
      p_cache_key="${p_cache_key/$var/${!var}}"
    done
  fi

  p_cache_key="${p_cache_key// -/-}"
  u_str_sanitize_var_name "$p_cache_key" 'p_cache_key'
  local hook_cache_file="scripts/cwt/local/cache/hook.${p_cache_key}.sh"

  if [[ -f "$hook_cache_file" ]]; then
    . "$hook_cache_file"
    return
  fi

  local hook_cache_contents=''

  local p_actions_filter
  local p_subjects_filter
  local p_prefixes_filter
  local p_variants_filter
  local p_extensions_filter
  local p_custom_filter
  local p_debug=0
  local p_dry_run=0
  local p_root_lookup=0
  local p_cache_warmup=0

  # Parse current function arguments.
  # See https://stackoverflow.com/a/31443098
  while [ "$#" -gt 0 ]; do
    case "$1" in
      # Format : 1 dash + arg 'name' + space + value.
      -a) p_actions_filter="$2"; shift 2;;
      -s) p_subjects_filter="$2"; shift 2;;
      -p) p_prefixes_filter="$2"; shift 2;;
      -v) p_variants_filter="$2"; shift 2;;
      -e) p_extensions_filter="$2"; shift 2;;
      -c) p_custom_filter="$2"; shift 2;;
      # Flag (arg without any value).
      -d) p_debug=1; shift 1;;
      -t) p_dry_run=1; shift 1;;
      -r) p_root_lookup=1; shift 1;;
      -w) p_cache_warmup=1; shift 1;;
      # Prevent unhandled arguments.
      -*) echo "Error in $BASH_SOURCE line $LINENO: unknown option: $1" >&2; return 1;;
      *) echo "Error in $BASH_SOURCE line $LINENO: unsupported unnamed argument: $1" >&2; return 2;;
    esac
  done

  # Enforce minimum conditions for triggering hook (see 5 in function docblock).
  if [ -z "$p_actions_filter" ] && [ -z "$p_extensions_filter" ] && [ -z "$p_variants_filter" ]; then
    echo
    echo "Error in $BASH_SOURCE line $LINENO: cannot trigger hook without either 1 action (or 1 extension + 1 variant)." >&2
    echo "-> Aborting." >&2
    echo
    return 1
  fi

  local prim_var
  local subjects="$CWT_SUBJECTS"
  local actions="$CWT_ACTIONS"
  local extensions="$CWT_EXTENSIONS"
  local variants=""
  local prefixes=""

  local base_paths=("cwt")
  local extension
  local uppercase
  local ext_path

  # Allow using only a particular extension (see the '-p' argument).
  if [ -n "$p_extensions_filter" ]; then
    for extension in $p_extensions_filter; do
      uppercase="$extension"
      u_str_sanitize_var_name "$uppercase" 'uppercase'
      u_str_uppercase "$uppercase"
      prim_var="${uppercase}_SUBJECTS"
      subjects="${!prim_var}"
      prim_var="${uppercase}_ACTIONS"
      actions="${!prim_var}"
      # Override base path for lookups.
      ext_path=''
      u_cwt_extension_path "$extension"
      base_paths=("$ext_path/$extension")
    done

  # By default, any extension can append its own "primitives".
  # NB : this process will create duplicates e.g. when extension has identical
  # subject(s) than cwt core. They are dealt with below.
  # @see u_cwt_extend()
  elif [ -n "$extensions" ]; then
    for extension in $extensions; do
      uppercase="$extension"
      u_str_sanitize_var_name "$uppercase" 'uppercase'
      u_str_uppercase "$uppercase"
      prim_var="${uppercase}_SUBJECTS"
      subjects+=" ${!prim_var}"
      prim_var="${uppercase}_ACTIONS"
      actions+=" ${!prim_var}"
      # Every extension defines an additional base path for lookups.
      ext_path=''
      u_cwt_extension_path "$extension"
      base_paths+=("$ext_path/$extension")
    done
  fi

  # Triggering a hook requires subjects and actions.
  if [ -z "$subjects" ]; then
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO: cannot trigger hook without any subjects." >&2
    echo "-> Aborting." >&2
    echo >&2
    return 2
  fi

  # Apply filters.
  local filters='subjects actions prefixes variants'
  local f
  local f_arg
  local f_arg_var
  local s
  local a
  local arg_val
  local dedup
  local dedup_val
  local dedup_arr

  for f in $filters; do

    # Use the same loop to remove potential duplicate values (cf. extensions above).
    dedup="${!f}"
    dedup_arr=()
    for dedup_val in $dedup; do
      u_array_add_once "$dedup_val" dedup_arr
    done
    eval "$f=\"${dedup_arr[@]}\""

    f_arg_var="p_${f}_filter"
    f_arg="${!f_arg_var}"
    if [ -z "$f_arg" ]; then
      continue
    fi

    declare "$f"=''

    case "$f" in
      subjects|prefixes|variants)
        for arg_val in $f_arg; do
          declare "$f"+="$arg_val "
        done
      ;;
      actions)
        for arg_val in $f_arg; do
          for s in $subjects; do
            declare "$f"+="$s/$arg_val "
          done
        done
      ;;
    esac
  done

  # Debug.
  # if [ $p_debug -eq 1 ]; then
  #   echo
  #   echo "debug hook call :"
  #   echo "  base_paths :"
  #   u_array_print 'base_paths'
  #   echo "  subjects = '$subjects'"
  #   echo "  actions = '$actions'"
  #   echo "  extensions = '$extensions'"
  #   echo "  variants = '$variants'"
  #   echo "  prefixes = '$prefixes'"
  # fi

  # Build lookup paths.
  local lookup_paths=()
  local lookup_subject

  for lookup_subject in $subjects; do
    u_hook_build_lookup_by_subject "$lookup_subject" "$p_custom_filter"
  done

  # Add support for project root lookup.
  if [ $p_root_lookup -eq 1 ]; then
    u_hook_build_project_root_dir_lookup "$p_actions_filter" "$p_custom_filter"
  fi

  # Debug.
  if [ $p_debug -eq 1 ]; then
    local debug_msg
    debug_msg='hook'
    if [[ -n "$p_subjects_filter" ]]; then
      debug_msg+=" -s '$p_subjects_filter'"
    fi
    if [[ -n "$p_actions_filter" ]]; then
      debug_msg+=" -a '$p_actions_filter'"
    fi
    if [[ -n "$p_custom_filter" ]]; then
      debug_msg+=" -c '$p_custom_filter'"
    fi
    if [[ -n "$p_variants_filter" ]]; then
      debug_msg+=" -v '$p_variants_filter'"
    fi
    if [[ -n "$p_prefixes_filter" ]]; then
      debug_msg+=" -p '$p_prefixes_filter'"
    fi
    if [[ -n "$p_extensions_filter" ]]; then
      debug_msg+=" -e '$p_extensions_filter'"
    fi
    if [ $p_root_lookup -eq 1 ]; then
      debug_msg+=" -r"
    fi
    u_autoload_print_lookup_paths lookup_paths "$debug_msg"
  fi

  # Source each file include (with optional override mecanism).
  # @see cwt/utilities/autoload.sh
  local inc
  for inc in "${lookup_paths[@]}"; do
    if [ -f "$inc" ]; then
      # Note : for tests, the "dry run" option prevents "override" alterations.
      # @see cwt/test/cwt/hook.test.sh
      # @see u_hook_most_specific()
      if [ $p_dry_run -eq 1 ]; then
        hook_dry_run_matches+="$inc
"
        continue
      fi

      # Update 2024-06 cache results.
      # Update 2025-04 cache warmup.
      local override=${p_script_path/cwt/"scripts/overrides"}

      if [[ -f "$override" ]]; then
        hook_cache_contents+=". $override
"
        if [[ $p_cache_warmup -ne 1 ]]; then
          . "$override"
        fi
        continue
      fi

      hook_cache_contents+=". $inc
"
      if [[ $p_cache_warmup -ne 1 ]]; then
        . "$inc"
      fi
    fi
  done

  # Update 2024-06 cache results.
  if [[ $p_dry_run -eq 1 ]]; then
    hook_cache_contents+="hook_dry_run_matches=\"$hook_dry_run_matches\""
  fi

  cat > "$hook_cache_file" <<CACHE
#!/usr/bin/env bash

##
# Generated cache file for hook $p_cache_key
#
# @see cwt/utilities/hook.sh
#

$hook_cache_contents

CACHE

  # Debug.
  # echo "New cache written for hook $p_cache_key"
}

##
# Adds hook lookup paths by subject.
#
# Side note : we could have every subject implement every other subjects' hooks,
# if we wanted to. E.g. env/app_bootstrap.hook.sh, etc. - but #YAGNI (mentionned
# here for potential future re-evaluation).
#
# @requires the following vars in calling scope :
# - $base_paths
# - $lookup_paths
# - $filters
# - $actions
#
# @uses the following optional vars in calling scope if available :
# - $prefixes
# - $variants
# - $p_prefixes_filter
#
# @see hook()
# @see u_autoload_add_lookup_level()
#
u_hook_build_lookup_by_subject() {
  local p_subject="$1"
  local p_suffix_override="$2"

  local bp

  local a_path
  local a_parts_arr
  local a

  local x_prim
  local x_parts_arr
  local x_val
  local x_values

  local v_prim
  local v_parts_arr
  local v
  local v_values
  local v_val
  local v_flag
  local v_fallback

  # By default, this function will produce lookup paths using the default
  # double-extension pattern "*.hook.sh". This can be altered when using the
  # custom filter argument (-c).
  local suffix='hook.sh'
  if [[ -n "$p_suffix_override" ]]; then
    suffix="$p_suffix_override"
  fi

  for bp in "${base_paths[@]}"; do

    # Avoid lookups for namespaces not having the subject we're looking for.
    if ! u_cwt_namespace_has_subject "$bp" "$p_subject" ; then
      continue
    fi

    for a_path in $actions; do

      # Ignore actions not "belonging" to current subject.
      case "$a_path" in "$p_subject"*)

        # First, add "pure" actions suggestions - unless excluded (see prefixes).
        if [[ -z "$p_prefixes_filter" ]]; then
          lookup_paths+=("$bp/${a_path}.${suffix}")
        fi

        u_str_split1 'a_parts_arr' "$a_path" '/'
        a="${a_parts_arr[1]}"

        # Then add "prefixed" actions suggestions.
        for x_val in $prefixes; do
          lookup_paths+=("$bp/$p_subject/${x_val}_${a}.${suffix}")
        done

        # Finally, add the variants suggestions.
        for v_prim in $variants; do
          v_val="${!v_prim}"
          if [[ "$v_values" != *"$v_val"* ]]; then
            v_values+="$v_val "
          fi
        done

        # Now that we fetched variants actual values, add them as as suggestions
        # unless excluded (see prefixes). These are combinatory, e.g. :
        # - init.local.dev.hook.sh
        # - bootstrap.docker-compose.dev.hook.sh
        # - bootstrap.docker-compose.prod.remote.hook.sh
        u_str_subsequences "$v_values" '.'
        if [[ -z "$p_prefixes_filter" ]]; then
          for v_val in $str_subsequences; do
            u_autoload_add_lookup_level "$bp/$p_subject/${a}." "$suffix" "$v_val" lookup_paths
          done
        fi

        # Implement prefix + variant lookup paths, e.g. :
        # pre_bootstrap.docker-compose.hook.sh
        for x_val in $prefixes; do
          for v_val in $str_subsequences; do
            u_autoload_add_lookup_level "$bp/$p_subject/${x_val}_${a}." "$suffix" "$v_val" lookup_paths
          done
        done
      esac
    done
  done
}

##
# Adds hook lookup paths in project root dir.
#
# @requires the following vars in calling scope :
# - $lookup_paths
# - $filters
# - $actions
#
# @uses the following optional vars in calling scope if available :
# - $prefixes
# - $variants
# - $p_prefixes_filter
#
# @see hook()
# @see u_autoload_add_lookup_level()
#
u_hook_build_project_root_dir_lookup() {
  local p_action="$1"
  local p_suffix_override="$2"

  local a

  local x_prim
  local x_parts_arr
  local x_val
  local x_values

  local v_prim
  local v_parts_arr
  local v
  local v_values
  local v_val
  local v_flag
  local v_fallback

  # TODO [evol] Whitelist possible values ?
  a="$p_action"

  # By default, this function will produce lookup paths using the default
  # double-extension pattern "*.hook.sh". This can be altered when using the
  # custom filter argument (-c).
  local suffix='hook.sh'
  if [[ -n "$p_suffix_override" ]]; then
    suffix="$p_suffix_override"
  fi

  # First, add "pure" actions suggestions - unless excluded (see prefixes).
  if [[ -z "$p_prefixes_filter" ]]; then
    lookup_paths+=("${a}.${suffix}")
  fi

  # Then add "prefixed" actions suggestions.
  for x_val in $prefixes; do
    lookup_paths+=("${x_val}_${a}.${suffix}")
  done

  # Finally, add the variants suggestions.
  for v_prim in $variants; do
    v_val="${!v_prim}"
    if [[ "$v_values" != *"$v_val"* ]]; then
      v_values+="$v_val "
    fi
  done

  # Now that we fetched variants actual values, add them as as suggestions
  # unless excluded (see prefixes). These are combinatory, e.g. :
  # - init.local.dev.hook.sh
  # - bootstrap.docker-compose.dev.hook.sh
  # - bootstrap.docker-compose.prod.remote.hook.sh
  u_str_subsequences "$v_values" '.'
  if [[ -z "$p_prefixes_filter" ]]; then
    for v_val in $str_subsequences; do
      u_autoload_add_lookup_level "${a}." "$suffix" "$v_val" lookup_paths
    done
  fi

  # Implement prefix + variant lookup paths, e.g. :
  # pre_bootstrap.docker-compose.hook.sh
  for x_val in $prefixes; do
    for v_val in $str_subsequences; do
      u_autoload_add_lookup_level "${x_val}_${a}." "$suffix" "$v_val" lookup_paths
    done
  done
}

##
# Same as hook() except it will only source the "most specific" match.
#
# This notion is totally arbitrary here - it will use the file having the
# deepest path and the highest number of dots in its path. In case of equality,
# the first match will be used.
#
# This "score" - a simple addition of slash & dot count in the filepath - allows
# to differenciate CWT's file-name-based implementations (hooks, globals,
# etc.) because of the way its patterns work :
#   - multiple extension (i.e. variants : pre_bootstrap.docker-compose.hook.sh)
#   - complements (e.g. scripts/complements/test/self_test.hook.sh)
#   - overrides (e.g. scripts/overrides/extensions/docker-compose/instance/init.docker-compose.hook.sh)
# @see hook()
#
# NB : We must give some advantage to the project-specific 'scripts' path in
# comparison to generic CWT extensions so that the custom implementations always
# take precedence over extensions'.
# -> Any implementation located in './scripts' gets +4 to its score.
#
# TODO [evol] Attempt to implement some control over which one gets sourced
# in case of equality.
#
# [optional] (re)sets the following var in calling scope :
# @var hook_most_specific_dry_run_match
#
# @example
#   # Basic usage - only sources 1 match (the "most specific") :
#   u_hook_most_specific -s 'instance' -a 'registry_get' -v 'HOST_TYPE'
#
#   # Dry run example.
#   # @see u_stack_template() in cwt/extensions/docker-compose/stack/stack.inc.sh
#   hook_most_specific_dry_run_match=''
#   u_hook_most_specific 'dry-run' -s 'stack' -a 'docker-compose' -c "yml" -v 'DC_YML_VARIANTS' -t
#   echo "$hook_most_specific_dry_run_match" # <- Prints the most specific "docker-compose.yml" found.
#
u_hook_most_specific() {
  local msdr_flag=0

  # Here we "preprocess" specific arguments and remove them if found to avoid
  # breaking the call to hook() below.
  # For now, only the first is checked - but we may have to loop through all of
  # them if we need more later on.
  case $1 in
    # Request to set an existing var in calling scope to the most specific match
    # found (instead of sourcing it).
    'dry-run')
      msdr_flag=1
      shift 1
    ;;
  esac

  local f
  local depth=0
  local dot_arr
  local slash_arr
  local highest_depth=0
  local most_specific_match=''
  local hook_dry_run_matches=''

  # Forwards all arguments while forcing the "dry run" (-t) flag.
  hook -t "$@"

  for f in $hook_dry_run_matches; do
    u_str_split1 'dot_arr' "$f" '.'
    u_str_split1 'slash_arr' "$f" '/'

    # Debug
    # echo "f.${#dot_arr[@]}.${#slash_arr[@]} : $f"
    # u_array_print dot_arr
    # u_array_print slash_arr

    depth=${#dot_arr[@]}
    depth=$(( depth + ${#slash_arr[@]} ))

    # Apply score bonus to custom project implementations so they take
    # precedence over extensions'.
    case "$f" in "scripts/"*)
      depth=$(( depth + 4 ))
    esac

    # Files in project root dir, when requested (-r), must have higher priority
    # than the default, generic extensions' (even the ones in scripts/*).
    if [[ ${#slash_arr[@]} -eq 1 ]]; then
      depth=$(( depth + 10 ))
    fi

    # Debug
    # echo "  -> adjusted depth = $depth"

    if [[ $depth -ge $highest_depth ]]; then
      most_specific_match="$f"
      highest_depth=$depth
    fi
  done

  if [[ -n "$most_specific_match" ]] && [[ -f "$most_specific_match" ]]; then
    # If the "dry run" flag is requested, it bypasses the override mechanism.
    # TODO can we workaround this ?
    if [[ $msdr_flag -eq 1 ]]; then
      hook_most_specific_dry_run_match="$most_specific_match"
      return
    fi

    u_autoload_override "$most_specific_match" 'continue'
    eval "$inc_override_evaled_code"

    . "$most_specific_match"
  fi
}
