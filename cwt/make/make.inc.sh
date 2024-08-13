#!/usr/bin/env bash

##
# Make-related utility functions.
#
# This file is sourced during core CWT bootstrap.
# @see cwt/bootstrap.sh
#
# Convention : functions names are all prefixed by "u" (for "utility").
#

##
# Make tasks arg safety check.
#
# Make sure none of the "arguments" passed in make calls would trigger unwanted
# targets (since we use it as aliases with completion in terminal).
#
# @example
#   # All args are checked.
#   u_make_check_args arg1 arg2
#
u_make_check_args() {
  local make_entries=()
  local real_scripts=()

  u_make_list_hardcoded
  u_make_list_entry_points

  if [[ -z "${make_entries[@]}" ]]; then
    echo >&2
    echo "Error in u_make_check_args() - $BASH_SOURCE line $LINENO: make entry points not found." >&2
    echo "It seems local instance hasn't been initialized yet." >&2
    echo "@see cwt/instance/init.sh" >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    exit 1
  fi

  local make_entry_point=''

  while [[ $# -gt 0 ]]; do
    for make_entry_point in "${make_entries[@]}"; do
      case "$1" in "$make_entry_point")
        echo >&2
        echo "The value '$1' is reserved as a Make entry point." >&2
        echo "-> Aborting (2)." >&2
        echo >&2
        exit 2
      esac
    done
    shift
  done
}

##
# Converts given string to a task name - e.g. for use as Make task.
#
# During conversion, some terms are abbreviated - e.g. :
#   - registry -> reg
#   - lookup-path -> lp
#   - docker-compose -> dc
#   - drupalwt -> dwt
#
# @param 1 String : input to convert.
# @param 2 [optional] String : the variable name in calling scope which will be
#   assigned the result. Defaults to 'task'.
#
# @var [default] task
#
u_make_task_name() {
  local p_str="$1"
  local p_itn_var_name="$2"

  if [[ -z "$p_itn_var_name" ]]; then
    p_itn_var_name='task'
  fi

  u_str_sanitize "$p_str" '-' 'p_str' '[^a-zA-Z0-9]'

  if [[ -n "$CWT_MAKE_TASKS_SHORTER" ]]; then
    local search_replace_pattern=''

    for search_replace_pattern in $CWT_MAKE_TASKS_SHORTER; do
      u_str_sanitize "$search_replace_pattern" '' 'search_replace_pattern' '[^a-zA-Z0-9\/\-_]'
      eval "p_str=\"\${p_str//$search_replace_pattern}\""
    done
  fi

  printf -v "$p_itn_var_name" '%s' "$p_str"
}

##
# Aggregates subject-action entry points to be used as Make tasks.
#
# This function writes its result to variables subject to collision in calling
# scope :
#
# @var make_entries
# @var real_scripts
#
# @example
#   make_entries=()
#   real_scripts=()
#
#   u_make_list_entry_points
#
#   for i in "${!real_scripts[@]}"; do
#     task="${make_entries[i]}"
#     script="${real_scripts[i]}"
#
#     echo "Make entry point $i :"
#     echo "  task = $task"
#     echo "  script = $script"
#   done
#
u_make_list_entry_points() {
  local extension
  local extension_var
  local extension_actions
  local extension_namespace
  local extension_iteration

  # From our "entry point" scripts' path, we need to provide a unique task
  # name -> we use subject-action pairs while preventing potential collisions
  # in case different extensions implement the same subject-action pair.
  # Important note : the arrays 'make_entries' and 'real_scripts' must have the
  # exact same order and size.
  local task
  local sa_pair
  local ext_path

  # No need to check for collisions in CWT core (we know there aren't any).
  for sa_pair in $CWT_ACTIONS; do
    task=''
    u_make_task_name "$sa_pair"

    # The 'instance' subject is a special case : we remove it to explicitly make
    # it the default subject. All actions belonging to the 'instance' subject
    # are transformed to the action part alone.
    # Exception : instance-init -> init = already hardcoded, so prevent adding
    # it twice. Same for setup.
    # @see cwt/instance/init.make.sh
    # @see Makefile (the one in PROJECT_DOCROOT path).
    case "$task" in instance-*)
      case "$task" in instance-init|instance-setup)
        continue
      esac
      task="${task#*instance-}"
    esac

    make_entries+=("$task")
    real_scripts+=("cwt/$sa_pair.sh")
  done

  # We need the custom 'extend' scripts folder to have priority for avoiding
  # "prefixed" aliases in case of collision with generic CWT extensions (so that
  # they get prefixed, not the project-specific implementation).
  # -> Move it first in iteration below.
  extension_iteration='extend'
  for extension in $CWT_EXTENSIONS; do
    case "$extension" in 'extend')
      continue
    esac
    extension_iteration+=" $extension"
  done

  for extension in $extension_iteration; do
    u_cwt_extension_namespace "$extension"
    extension_var="${extension_namespace}_ACTIONS"
    extension_actions="${!extension_var}"

    if [[ -n "$extension_actions" ]]; then
      # Extensions' subject-action pairs must yield unique tasks -> check for
      # collisions.
      for sa_pair in $extension_actions; do
        task=''
        u_make_task_name "$sa_pair"

        case "$task" in instance-*)
          task="${task#*instance-}"
        esac

        if u_in_array "$task" 'make_entries'; then
          task="${extension}-$task"
          u_make_task_name "$task"
        fi

        make_entries+=("$task")
        ext_path=''
        u_cwt_extension_path "$extension"
        # TODO [minor] Figure out why this can produce duplicate entries.
        # real_scripts+=("$ext_path/$extension/$sa_pair.sh")
        u_array_add_once "$ext_path/$extension/$sa_pair.sh" real_scripts
      done
    fi
  done
}

##
# Writes make entrypoints to scripts/cwt/local/generated.mk
#
# Generates a Makefile include with tasks corresponding to every subject-action
# in current instance.
#
# Also generates a script called before any make entry point to do the same as :
# @see u_make_check_args()
#
u_make_generate() {
  local i
  local make_entry_point
  local real_script

  local make_entries=()
  local real_scripts=()

  # All except the hardcoded ones.
  u_make_list_entry_points

  if [[ -z "$real_scripts" ]]; then
    echo "Notice in u_make_generate() - $BASH_SOURCE line $LINENO: no Make entry points have been found."
    return
  fi

  echo "Writing Makefile include scripts/cwt/local/generated.mk ..."

  cat > scripts/cwt/local/generated.mk <<'EOF'
SHELL := /usr/bin/env bash

##
# Current instance Makefile include.
#
# Contains generic tasks for subject-action entry points (default scripts).
#
# This file is automatically generated during "instance init", and it will be
# entirely overwritten every time it is executed.
#
# @see u_instance_init() in cwt/instance/instance.inc.sh
# @see u_make_generate() in cwt/make/make.inc.sh
#

EOF

  for i in "${!make_entries[@]}"; do
    make_entry_point="${make_entries[i]}"
    real_script="${real_scripts[i]}"

    echo ".PHONY: $make_entry_point
$make_entry_point:
	@ cwt/make/call_wrap.make.sh $real_script \$(MAKECMDGOALS)
" >> scripts/cwt/local/generated.mk

  done

  echo "Writing Makefile include scripts/cwt/local/generated.mk : done."
  echo

  # We'll also need to generate a "normal" shell script (not bash) to check
  # that among all arguments sent to a Make entry point, none are "reserved"
  # values - i.e. that would trigger unwanted other targets.
  echo "Creating cache file scripts/cwt/local/cache/make.sh ..."

  # Including the hardcoded ones (this is only used for the safety check).
  u_make_list_hardcoded

  local cache_file='scripts/cwt/local/cache/make.sh'
  local make_entries_code_gen=''
  local real_scripts_code_gen=''

  # Replace contents in case cache file exists.
  cat > "$cache_file" <<'SHELL_SCRIPT_HEAD'

##
# Cache the list of make entry points.
#
# This script is generated during "instance init".
#
# @see u_instance_init() in cwt/instance/instance.inc.sh
# @see u_make_generate() in cwt/make/make.inc.sh
#

make_entries=()
real_scripts=()

SHELL_SCRIPT_HEAD

  for i in "${!make_entries[@]}"; do
    make_entry_point="${make_entries[i]}"
    real_script="${real_scripts[i]}"

    make_entries_code_gen+="make_entries+=('$make_entry_point')
"
    real_scripts_code_gen+="real_scripts+=('$real_script')
"
  done

  echo '' >> "$cache_file"
  echo "$make_entries_code_gen" >> "$cache_file"
  echo '' >> "$cache_file"
  echo "$real_scripts_code_gen" >> "$cache_file"

  echo "Creating cache file scripts/cwt/local/cache/make.sh : done."
  echo
}

##
# Single source of truth for hardcoded Make entry points.
#
# Manually list our own hardcoded entries.
#
# @see cwt/make/default.mk
#
# This function writes its result to variables subject to collision in calling
# scope :
#
# @var make_entries
# @var real_scripts
#
# @example
#   make_entries=()
#   real_scripts=()
#   u_make_list_hardcoded
#
u_make_list_hardcoded() {
  make_entries+=('init')
  real_scripts+=('cwt/instance/init.make.sh')
  make_entries+=('init-debug')
  real_scripts+=('cwt/instance/init.make.sh -d -r')
  # make_entries+=('reinit')
  # real_scripts+=('cwt/instance/reinit.sh')
  make_entries+=('setup')
  real_scripts+=('cwt/instance/setup.sh')
  make_entries+=('hook')
  real_scripts+=('cwt/instance/hook.make.sh')
  make_entries+=('hook-debug')
  real_scripts+=('cwt/instance/hook.make.sh -d -t')
  make_entries+=('globals-lp')
  real_scripts+=('cwt/env/global_lookup_paths.make.sh')
  make_entries+=('self-test')
  real_scripts+=('cwt/test/self_test.sh')
  make_entries+=('debug')
  real_scripts+=('cwt/make/echo.make.sh')
}

##
# Make cannot handle the '=' sign (by design).
#
# TODO [evol] find better workaround than the '∓' swap.
#
# @see cwt/escape.sh
# @see cwt/make/call_wrap.make.sh
#
u_make_unescape() {
  local p_arg="$1"
  local p_var_name="$2"

  if [[ -z "$p_var_name" ]]; then
    p_var_name='unescaped_arg'
  fi

  unescaped_arg="$p_arg"

  case "$p_arg" in *'∓'*)
    unescaped_arg="${unescaped_arg//'\$'/'$'}"
    unescaped_arg="${unescaped_arg//'∓'/'='}"
  esac

  # Debug
  # echo "u_make_unescape $p_var_name = $unescaped_arg"

  printf -v "$p_var_name" '%s' "$unescaped_arg"
}
