
##
# Make entry points arguments safety check.
#
# This ensures none of the "arguments" passed in make calls would trigger
# unwanted targets (since we use it as a kind of aliases list).
#
# This script is harcoded for the default Make entry points, because they can be
# called before the local instance is initialized and the generated list does
# not exist yet.
#
# @see u_instance_init() in cwt/instance/instance.inc.sh
# @see u_make_generate() in cwt/make/make.inc.sh
# @see scripts/cwt/local/make_args_check.sh
#

# Use the complete generated check if it exists.
if [ -f scripts/cwt/local/make_args_check.sh ]; then
  scripts/cwt/local/make_args_check.sh $@
  exit $?
fi

make_entry_point="$1"
shift
rest_of_args="$@"

reserved_values="init init-debug setup hook hook-debug globals-lp self-test"

while [ $# -gt 0 ]; do
  for entry in $reserved_values; do
    case "$1" in "$entry")
      echo >&2
      echo "The value '$1' is reserved as a Make entry point." >&2
      echo "Use the following equivalent command instead :" >&2
      echo >&2

      case "$make_entry_point" in
        init)
          echo "cwt/instance/init.make.sh $rest_of_args" >&2
          ;;
        init-debug)
          echo "cwt/instance/init.make.sh -d -r $rest_of_args" >&2
          ;;
        setup)
          echo "cwt/instance/setup.sh $rest_of_args" >&2
          ;;
        hook)
          echo "cwt/instance/hook.make.sh $rest_of_args" >&2
          ;;
        hook-debug)
          echo "cwt/instance/hook.make.sh -d -t $rest_of_args" >&2
          ;;
        globals-lp)
          echo "cwt/env/global_lookup_paths.make.sh $rest_of_args" >&2
          ;;
        self-test)
          echo "cwt/test/self_test.sh $rest_of_args" >&2
          ;;
      esac

      echo >&2
      exit 1
    esac
  done

  shift
done
