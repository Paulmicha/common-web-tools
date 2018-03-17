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

  touch "$extensions_dir/nftcwthdehnc/app/nftcwthhnc_dry_run.hook.sh"
  touch "$extensions_dir/nftcwthdehnc/stack/nftcwthhnc_dry_run.hook.sh"
  touch "$extensions_dir/nftcwthdehnc/remote/nftcwthhnc_dry_run.hook.sh"

  # Forces detection of our newly created temporary extension.
  u_cwt_extend

  echo "  CWT_EXTENSIONS = '$CWT_EXTENSIONS'"
}

##
# Do single action hooks call every matching files ?
#
test_cwt_hook_single_action() {
  local inc_dry_run_files_list=''

  echo "  CWT_EXTENSIONS = '$CWT_EXTENSIONS'"

  hook -a 'nftcwthhnc_dry_run' -t
  echo "inc_dry_run_files_list = $inc_dry_run_files_list"

  assertTrue 'Global CWT_INC is empty (bootstrap test failed)' "[ -ne $CWT_INC ]"
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
  u_cwt_get_extensions_dir
  rm -fr "$extensions_dir/nftcwthdehnc"
}

# Load and run shUnit2.
. cwt/vendor/shunit2/shunit2
