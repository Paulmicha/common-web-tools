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
# TODO test dotfiles like '.cwt_subjects_ignore' in extensions.
# TODO test folder names with dots (extensions + subjects + actions + prefixes).
#
# @example
#   cwt/test/cwt/hook.test.sh
#

. cwt/bootstrap.sh
. cwt/test/self_test.inc.sh

##
# Creates temporary files for verification purposes in current test case.
#
# (Internal shunit2 function called before all tests have run.)
#
oneTimeSetUp() {
  local s
  for s in $CWT_SUBJECTS; do
    touch "cwt/$s/nftcwthhnc_dry_run.hook.sh"

    # Failsafe : cannot carry on if touch did not complete without error.
    if [[ $? -ne 0 ]]; then
      echo >&2
      echo "Error (2) in $BASH_SOURCE line $LINENO: cannot create temporary file for testing CWT hooks." >&2
      echo "-> aborting" >&2
      echo >&2
      exit 2
    fi
  done

  # Also test with a dummy extension (requires bootstrap reload, see below).
  # Failsafe : cannot carry on without an existing CWT extensions dir.
  if [[ ! -d "cwt/extensions" ]]; then
    echo >&2
    echo "Error (3) in $BASH_SOURCE line $LINENO: CWT extensions dir does not exist." >&2
    echo "-> aborting" >&2
    echo >&2
    exit 3
  fi

  mkdir -p "cwt/extensions/nftcwthdehnc/app"

  # Failsafe : cannot carry on without successful temporary extension dir creation.
  if [[ $? -ne 0 ]]; then
    echo >&2
    echo "Error (4) in $BASH_SOURCE line $LINENO: cannot create temporary extension dir for testing hooks." >&2
    echo "-> aborting" >&2
    echo >&2
    exit 4
  fi

  mkdir "cwt/extensions/nftcwthdehnc/stack"
  mkdir "cwt/extensions/nftcwthdehnc/remote"
  mkdir "cwt/extensions/nftcwthdehnc/test"

  # Empty files are enough to trigger positive detection during CWT primitives
  # values aggregation during bootstrap and during hook lookup paths generation.
  # @see u_cwt_extend()
  # @see hook()
  touch "cwt/extensions/nftcwthdehnc/app/nftcwthhnc_dry_run.hook.sh"
  touch "cwt/extensions/nftcwthdehnc/stack/nftcwthhnc_dry_run.hook.sh"
  touch "cwt/extensions/nftcwthdehnc/remote/nftcwthhnc_dry_run.hook.sh"
  touch "cwt/extensions/nftcwthdehnc/test/nftcwthhnc_dry_run.sh"

  # Variants tests require the following globals. We set them with dummy values
  # if instance init hasn't been run in current instance yet.
  # @see u_instance_init()
  # @see cwt/instance/init.sh
  if [[ -z "$INSTANCE_TYPE" ]]; then
    INSTANCE_TYPE='dev'
  fi
  if [[ -z "$HOST_TYPE" ]]; then
    HOST_TYPE='local'
  fi
  touch "cwt/extensions/nftcwthdehnc/test/nftcwthhnc_dry_run.$INSTANCE_TYPE.hook.sh"
  touch "cwt/extensions/nftcwthdehnc/test/nftcwthhnc_dry_run.$HOST_TYPE.hook.sh"
  touch "cwt/extensions/nftcwthdehnc/test/nftcwthhnc_dry_run.$HOST_TYPE.$INSTANCE_TYPE.hook.sh"

  # Prefix tests.
  touch "cwt/extensions/nftcwthdehnc/test/pre_nftcwthhnc_dry_run.hook.sh"
  touch "cwt/extensions/nftcwthdehnc/test/post_nftcwthhnc_dry_run.hook.sh"
  touch "cwt/extensions/nftcwthdehnc/test/post_nftcwthhnc_dry_run.$INSTANCE_TYPE.hook.sh"
  touch "cwt/extensions/nftcwthdehnc/test/post_nftcwthhnc_dry_run.$HOST_TYPE.hook.sh"
  touch "cwt/extensions/nftcwthdehnc/test/undo_nftcwthhnc_dry_run.$HOST_TYPE.$INSTANCE_TYPE.hook.sh"

  # Forces detection of our newly created temporary extension.
  u_cwt_extend
}

##
# Will single action hooks load every matching files and none other ?
#
test_cwt_hook_single_action() {
  local hook_dry_run_matches=''
  local expected_list="cwt/app/nftcwthhnc_dry_run.hook.sh
cwt/extensions/nftcwthdehnc/app/nftcwthhnc_dry_run.hook.sh
cwt/git/nftcwthhnc_dry_run.hook.sh
cwt/host/nftcwthhnc_dry_run.hook.sh
cwt/instance/nftcwthhnc_dry_run.hook.sh
cwt/extensions/nftcwthdehnc/remote/nftcwthhnc_dry_run.hook.sh
cwt/test/nftcwthhnc_dry_run.hook.sh
cwt/extensions/nftcwthdehnc/test/nftcwthhnc_dry_run.$INSTANCE_TYPE.hook.sh
cwt/extensions/nftcwthdehnc/stack/nftcwthhnc_dry_run.hook.sh
"
  hook -a 'nftcwthhnc_dry_run' -t

  u_test_compare_expected_lookup_paths
  u_test_lookup_paths_assertion "Single action hook test failed." $flag
}

##
# Does subject filter work ?
#
test_cwt_hook_subject() {
  local hook_dry_run_matches=''
  local expected_list="cwt/test/nftcwthhnc_dry_run.hook.sh
cwt/extensions/nftcwthdehnc/test/nftcwthhnc_dry_run.$INSTANCE_TYPE.hook.sh"

  hook -a 'nftcwthhnc_dry_run' -s 'test' -t

  u_test_compare_expected_lookup_paths
  u_test_lookup_paths_assertion "Subject filter hook test failed." $flag
}

##
# Does combinatory variants filter work ?
#
test_cwt_hook_combinatory_variants() {
  local hook_dry_run_matches=''
  local expected_list="cwt/extensions/nftcwthdehnc/test/nftcwthhnc_dry_run.$INSTANCE_TYPE.hook.sh
cwt/extensions/nftcwthdehnc/test/nftcwthhnc_dry_run.$HOST_TYPE.$INSTANCE_TYPE.hook.sh
cwt/extensions/nftcwthdehnc/test/nftcwthhnc_dry_run.$HOST_TYPE.hook.sh
"

  # hook -a 'nftcwthhnc_dry_run' -s 'test' -e 'nftcwthdehnc' -v 'HOST_TYPE INSTANCE_TYPE' -t -d
  # echo
  hook -a 'nftcwthhnc_dry_run' -s 'test' -e 'nftcwthdehnc' -v 'HOST_TYPE INSTANCE_TYPE' -t

  u_test_compare_expected_lookup_paths
  u_test_lookup_paths_assertion "Combinatory variants filter hook test failed." $flag
}

##
# Does prefix filter work ?
#
test_cwt_hook_prefix() {
  local hook_dry_run_matches=''
  local expected_list="cwt/extensions/nftcwthdehnc/test/pre_nftcwthhnc_dry_run.hook.sh"

  hook -a 'nftcwthhnc_dry_run' -p 'pre' -t

  u_test_compare_expected_lookup_paths
  u_test_lookup_paths_assertion "Prefix filter hook test failed." $flag
}

##
# Does prefix filter work with default variants ?
#
test_cwt_hook_prefix_variants() {
  local hook_dry_run_matches=''
  local expected_list="cwt/extensions/nftcwthdehnc/test/post_nftcwthhnc_dry_run.hook.sh
cwt/extensions/nftcwthdehnc/test/post_nftcwthhnc_dry_run.$INSTANCE_TYPE.hook.sh
"

  hook -a 'nftcwthhnc_dry_run' -s 'test' -e 'nftcwthdehnc' -p 'post' -t

  u_test_compare_expected_lookup_paths
  u_test_lookup_paths_assertion "Prefix + variants filter hook test failed." $flag
}

##
# Does prefix filter work with combinatory variants ?
#
test_cwt_hook_prefix_combinatory_variants() {
  local hook_dry_run_matches=''
  local expected_list="cwt/extensions/nftcwthdehnc/test/undo_nftcwthhnc_dry_run.$HOST_TYPE.$INSTANCE_TYPE.hook.sh"

  hook -a 'nftcwthhnc_dry_run' -s 'test' -v 'HOST_TYPE INSTANCE_TYPE' -p 'undo' -t

  u_test_compare_expected_lookup_paths
  u_test_lookup_paths_assertion "Prefix + combinatory variants filter hook test failed." $flag
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
  rm -fr "cwt/extensions/nftcwthdehnc"
}

# Load and run shUnit2.
. cwt/vendor/shunit2/shunit2
