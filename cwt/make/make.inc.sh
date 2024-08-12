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
  local mk_tasks=()
  local mk_entry_points=()

  # Manually add our own hardcoded entries.
  # @see cwt/make/default.mk
  mk_tasks+=('init')
  mk_entry_points+=('cwt/instance/init.make.sh')
  mk_tasks+=('init-debug')
  mk_entry_points+=('cwt/instance/init.make.sh -d -r')
  mk_tasks+=('setup')
  mk_entry_points+=('cwt/instance/setup.sh')
  mk_tasks+=('hook')
  mk_entry_points+=('cwt/instance/hook.make.sh')
  mk_tasks+=('hook-debug')
  mk_entry_points+=('cwt/instance/hook.make.sh -d -t')
  mk_tasks+=('globals-lp')
  mk_entry_points+=('cwt/env/global_lookup_paths.make.sh')
  mk_tasks+=('self-test')
  mk_entry_points+=('cwt/test/self_test.sh')

  u_make_list_entry_points

  if [[ -z "${mk_tasks[@]}" ]]; then
    echo >&2
    echo "Error in u_make_check_args() - $BASH_SOURCE line $LINENO: make entry points not found." >&2
    echo "It seems local instance hasn't been initialized yet." >&2
    echo "@see cwt/instance/init.sh" >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    exit 1
  fi

  local entry=''

  while [[ $# -gt 0 ]]; do
    for entry in "${mk_tasks[@]}"; do
      case "$1" in "$entry")
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
# @var mk_tasks
# @var mk_entry_points
#
# @example
#   mk_tasks=()
#   mk_entry_points=()
#
#   u_make_list_entry_points
#
#   for index in "${!mk_entry_points[@]}"; do
#     task="${mk_tasks[index]}"
#     script="${mk_entry_points[index]}"
#
#     echo "Make entry point $index :"
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
  # Important note : the arrays 'mk_tasks' and 'mk_entry_points' must have the
  # exact same order and size.
  local index

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

    mk_tasks+=("$task")
    mk_entry_points+=("cwt/$sa_pair.sh")
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

        if u_in_array "$task" 'mk_tasks'; then
          task="${extension}-$task"
          u_make_task_name "$task"
        fi

        mk_tasks+=("$task")
        ext_path=''
        u_cwt_extension_path "$extension"
        # TODO [minor] Figure out why this can produce duplicate entries.
        # mk_entry_points+=("$ext_path/$extension/$sa_pair.sh")
        u_array_add_once "$ext_path/$extension/$sa_pair.sh" mk_entry_points
      done
    fi
  done
}

##
# Writes make entrypoints to scripts/cwt/local/default.mk
#
# Generates a Makefile include with tasks corresponding to every subject-action
# in current instance.
#
# Also generates a script called before any make entry point to do the same as :
# @see u_make_check_args()
#
u_make_generate() {
  local index
  local task
  local script
  local mk_tasks=()
  local mk_entry_points=()

  u_make_list_entry_points

  if [[ -z "$mk_entry_points" ]]; then
    echo "Notice in u_make_generate() - $BASH_SOURCE line $LINENO: no Make entry points have been found."
    return
  fi

  echo "Writing generic Makefile include scripts/cwt/local/default.mk ..."

  cat > scripts/cwt/local/default.mk <<'EOF'

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

  for index in "${!mk_entry_points[@]}"; do
    task="${mk_tasks[index]}"

    echo ".PHONY: $task
$task:
	@ scripts/cwt/local/make_args_check.sh \$(MAKECMDGOALS) && ${mk_entry_points[index]} \$(filter-out \$@,\$(MAKECMDGOALS))
" >> scripts/cwt/local/default.mk

  done

  echo "Writing generic Makefile include scripts/cwt/local/default.mk : done."
  echo

  # We'll also need to generate a "normal" shell script (not bash) to check
  # that among all arguments sent to a Make entry point, none are "reserved"
  # values - i.e. that would trigger unwanted other targets.
  echo "Writing arguments checker script scripts/cwt/local/make_args_check.sh ..."

  cat > scripts/cwt/local/make_args_check.sh <<'SHELL_SCRIPT_HEAD'

##
# Make entry points arguments safety check.
#
# This ensures none of the "arguments" passed in make calls would trigger
# unwanted targets (since we use it as a kind of aliases list).
#
# This script is generated during "instance init".
#
# @see u_instance_init() in cwt/instance/instance.inc.sh
# @see u_make_generate() in cwt/make/make.inc.sh
#

# We'll provide fallback command to use as feedback.
make_entry_point="$1"
shift
rest_of_args="$@"

SHELL_SCRIPT_HEAD

  local reserved_values=''
  local feedback_code=''

  feedback_code+='case "$make_entry_point" in
'

  # Manually add our own hardcoded entries.
  # @see cwt/make/default.mk
  mk_tasks+=('init')
  mk_entry_points+=('cwt/instance/init.make.sh')
  mk_tasks+=('init-debug')
  mk_entry_points+=('cwt/instance/init.make.sh -d -r')
  mk_tasks+=('setup')
  mk_entry_points+=('cwt/instance/setup.sh')
  mk_tasks+=('hook')
  mk_entry_points+=('cwt/instance/hook.make.sh')
  mk_tasks+=('hook-debug')
  mk_entry_points+=('cwt/instance/hook.make.sh -d -t')
  mk_tasks+=('globals-lp')
  mk_entry_points+=('cwt/env/global_lookup_paths.make.sh')
  mk_tasks+=('self-test')
  mk_entry_points+=('cwt/test/self_test.sh')

  for index in "${!mk_entry_points[@]}"; do
    task="${mk_tasks[index]}"
    script="${mk_entry_points[index]}"

    reserved_values+="$task "

    feedback_code+="        $task)
"
    feedback_code+="          echo \"$script \$rest_of_args\" >&2
"
    feedback_code+="          ;;
"
  done

  feedback_code+='      esac
'

  echo "reserved_values=\"$reserved_values\"" >> scripts/cwt/local/make_args_check.sh

  cat >> scripts/cwt/local/make_args_check.sh <<SHELL_SCRIPT_BODY

while [ \$# -gt 0 ]; do
  for entry in \$reserved_values; do
    case "\$1" in "\$entry")
      echo >&2
      echo "The value '\$1' is reserved as a Make entry point." >&2
      echo "Use the following equivalent command instead :" >&2
      echo >&2

      $feedback_code

      echo >&2
      exit 1
    esac
  done

  shift
done

SHELL_SCRIPT_BODY

  echo "Writing arguments checker script scripts/cwt/local/make_args_check.sh : done."
  echo
}
