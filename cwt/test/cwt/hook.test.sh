#!/usr/bin/env bash

##
# CWT core hook-related tests.
#
# @requires cwt/vendor/shunit2
#
# This file may be dynamically executed.
# @see cwt/test/cwt.sh
#
# List of acronyms used (must not collide) :
# - nftcwthhnc = name for testing CWT hooks hopefully not colliding
# - nftcwthdehnc = name for testing CWT hooks dummy extension hopefully not colliding
#
# @example
#   cwt/test/cwt/hook.test.sh
#

. cwt/bootstrap.sh

##
# Creates temporary files for verification purposes in current test case.
#
# (Internal shunit2 function called before all tests have run.)
#
oneTimeSetUp() {
  local s
  for s in $CWT_SUBJECTS; do
    touch "cwt/$s/nftcwthhnc_dry_run.hook.sh"
  done

  # Also test with a dummy extension (requires bootstrap reload, see below).
  u_cwt_get_extensions_dir

  # Failsafe : cannot carry on without an existing CWT extensions dir.
  if [[ ! -d "$extensions_dir" ]]; then
    echo >&2
    echo "Error (3) in $BASH_SOURCE line $LINENO: CWT extensions dir does not exist." >&2
    echo "-> aborting" >&2
    echo >&2
    exit 3
  fi

  mkdir -p "$extensions_dir/nftcwthdehnc/app"

  # Failsafe : cannot carry on without successful temporary extension dir creation.
  if [[ $? -ne 0 ]]; then
    echo >&2
    echo "Error (4) in $BASH_SOURCE line $LINENO: cannot create temporary extension dir for testing hooks." >&2
    echo "-> aborting" >&2
    echo >&2
    exit 4
  fi

  mkdir "$extensions_dir/nftcwthdehnc/stack"
  mkdir "$extensions_dir/nftcwthdehnc/remote"
  mkdir "$extensions_dir/nftcwthdehnc/test"

  # Empty files are enough to trigger positive detection during CWT primitives
  # values aggregation during bootstrap and during hook lookup paths generation.
  # @see u_cwt_extend()
  # @see hook()
  touch "$extensions_dir/nftcwthdehnc/app/nftcwthhnc_dry_run.hook.sh"
  touch "$extensions_dir/nftcwthdehnc/stack/nftcwthhnc_dry_run.hook.sh"
  touch "$extensions_dir/nftcwthdehnc/remote/nftcwthhnc_dry_run.hook.sh"
  touch "$extensions_dir/nftcwthdehnc/test/nftcwthhnc_dry_run.sh"

  # Variants tests require the following globals. We set them with dummy values
  # if stack init hasn't been run in current instance yet.
  # @see cwt/stack/init.sh
  # @see cwt/env/write.sh
  if [[ -z "$INSTANCE_TYPE" ]]; then
    INSTANCE_TYPE='dev'
  fi
  if [[ -z "$HOST_TYPE" ]]; then
    HOST_TYPE='local'
  fi
  touch "$extensions_dir/nftcwthdehnc/test/nftcwthhnc_dry_run.$INSTANCE_TYPE.hook.sh"
  touch "$extensions_dir/nftcwthdehnc/test/nftcwthhnc_dry_run.$HOST_TYPE.hook.sh"

  # Forces detection of our newly created temporary extension.
  u_cwt_extend
}

##
# Custom hook test assertion helper.
#
# @param 1 String : failed test error message.
# @param 2 Int : numerical flag (error number).
#
_cwt_hook_test_assertion_helper() {
  local p_msg="$1"
  local p_flag=$2

  local fail_reason
  case $flag in
    1) fail_reason='missing matching lookup paths' ;;
    2) fail_reason='too many matching lookup paths' ;;
    *) fail_reason='unexpected error' ;;
  esac

  assertTrue "$p_msg (error $flag : $fail_reason)" "[ $flag -eq 0 ]"
}

##
# Will single action hooks load every matching files and none other ?
#
test_cwt_hook_single_action() {
  local inc_dry_run_files_list=''
  local flag=1
  local i

  hook -a 'nftcwthhnc_dry_run' -t

  for i in $inc_dry_run_files_list; do
    case "$i" in
      # All these matches must be found.
      'cwt/app/nftcwthhnc_dry_run.hook.sh' | \
      "$extensions_dir/nftcwthdehnc/app/nftcwthhnc_dry_run.hook.sh" | \
      'cwt/cron/nftcwthhnc_dry_run.hook.sh' | \
      'cwt/db/nftcwthhnc_dry_run.hook.sh' | \
      'cwt/env/nftcwthhnc_dry_run.hook.sh' | \
      'cwt/git/nftcwthhnc_dry_run.hook.sh' | \
      'cwt/instance/nftcwthhnc_dry_run.hook.sh' | \
      'cwt/remote/nftcwthhnc_dry_run.hook.sh' | \
      "$extensions_dir/nftcwthdehnc/remote/nftcwthhnc_dry_run.hook.sh" | \
      'cwt/service/nftcwthhnc_dry_run.hook.sh' | \
      'cwt/stack/nftcwthhnc_dry_run.hook.sh' | \
      "$extensions_dir/nftcwthdehnc/stack/nftcwthhnc_dry_run.hook.sh" | \
      "$extensions_dir/nftcwthdehnc/test/nftcwthhnc_dry_run.$INSTANCE_TYPE.hook.sh")
        flag=0
      ;;
      # None other must match.
      *)
        flag=2
      ;;
    esac
  done

  _cwt_hook_test_assertion_helper "Single action hook test failed." $flag
}

##
# Do subject filter work ?
#
test_cwt_hook_subject_filter() {
  local inc_dry_run_files_list=''
  local flag=0
  local i

  hook -a 'nftcwthhnc_dry_run' -s 'test' -t

  for i in $inc_dry_run_files_list; do
    case "$i" in
      "$extensions_dir/nftcwthdehnc/test/nftcwthhnc_dry_run.$INSTANCE_TYPE.hook.sh")
        flag=0
      ;;
      *)
        flag=2
      ;;
    esac
  done

  _cwt_hook_test_assertion_helper "Subject filter hook test failed." $flag
}

##
# Do combinatory variants filter work ?
#
test_cwt_hook_combinatory_variants() {
  local inc_dry_run_files_list=''
  local flag=0
  local i

  hook -a 'nftcwthhnc_dry_run' -s 'test' -v 'INSTANCE_TYPE HOST_TYPE' -t

  for i in $inc_dry_run_files_list; do
    case "$i" in
      "$extensions_dir/nftcwthdehnc/test/nftcwthhnc_dry_run.$INSTANCE_TYPE.hook.sh" | \
      "$extensions_dir/nftcwthdehnc/test/nftcwthhnc_dry_run.$HOST_TYPE.hook.sh")
        flag=0
      ;;
      *)
        flag=2
      ;;
    esac
  done

  _cwt_hook_test_assertion_helper "Combinatory variants filter hook test failed." $flag
}

##
# Cleans up any leftovers from previous tests.
#
# (Internal shunit2 function called after all tests have run.)
#
oneTimeTearDown() {
  local s
  for s in $CWT_SUBJECTS; do
    rm -f "cwt/$s/nftcwthhnc_dry_run.hook.sh"
  done
  rm -fr "$extensions_dir/nftcwthdehnc"
}

# Load and run shUnit2.
. cwt/vendor/shunit2/shunit2
