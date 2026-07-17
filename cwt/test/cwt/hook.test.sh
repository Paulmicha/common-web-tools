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
. cwt/test/cwt.inc.sh

##
# Creates temporary files for verification purposes in current test case.
#
oneTimeSetUp() {
  local s

  # Clear dry-run hook caches so newly touched files are visible.
  # @see hook() in cwt/utilities/hook.sh
  rm -f data/cwt/cache/hook.*nftcwthhnc*

  for s in $CWT_SUBJECTS; do
    # bootstrap/ holds phase includes, not a normal subject action namespace.
    case "$s" in bootstrap) continue ;; esac
    touch "cwt/$s/nftcwthhnc_dry_run.hook.sh"

    if [[ $? -ne 0 ]]; then
      echo >&2
      echo "Error (2) in $BASH_SOURCE line $LINENO: cannot create temporary file for testing CWT hooks." >&2
      echo "-> aborting" >&2
      echo >&2
      exit 2
    fi
  done

  if [[ ! -d "cwt/extensions" ]]; then
    echo >&2
    echo "Error (3) in $BASH_SOURCE line $LINENO: CWT extensions dir does not exist." >&2
    echo "-> aborting" >&2
    echo >&2
    exit 3
  fi

  # Dummy extension subjects reuse core subject names plus extra ones so hook
  # subject scanning covers extension namespaces (no dependency on removed
  # core `app` / `presets` subjects).
  mkdir -p "cwt/extensions/nftcwthdehnc/instance"
  mkdir -p "cwt/extensions/nftcwthdehnc/stack"
  mkdir -p "cwt/extensions/nftcwthdehnc/remote"
  mkdir -p "cwt/extensions/nftcwthdehnc/test"

  if [[ $? -ne 0 ]]; then
    echo >&2
    echo "Error (4) in $BASH_SOURCE line $LINENO: cannot create temporary extension dir for testing hooks." >&2
    echo "-> aborting" >&2
    echo >&2
    exit 4
  fi

  touch "cwt/extensions/nftcwthdehnc/instance/nftcwthhnc_dry_run.hook.sh"
  touch "cwt/extensions/nftcwthdehnc/stack/nftcwthhnc_dry_run.hook.sh"
  touch "cwt/extensions/nftcwthdehnc/remote/nftcwthhnc_dry_run.hook.sh"
  touch "cwt/extensions/nftcwthdehnc/test/nftcwthhnc_dry_run.sh"

  if [[ -z "$INSTANCE_TYPE" ]]; then
    INSTANCE_TYPE='dev'
  fi
  if [[ -z "$HOST_TYPE" ]]; then
    HOST_TYPE='local'
  fi
  touch "cwt/extensions/nftcwthdehnc/test/nftcwthhnc_dry_run.$INSTANCE_TYPE.hook.sh"
  touch "cwt/extensions/nftcwthdehnc/test/nftcwthhnc_dry_run.$HOST_TYPE.hook.sh"
  touch "cwt/extensions/nftcwthdehnc/test/nftcwthhnc_dry_run.$HOST_TYPE.$INSTANCE_TYPE.hook.sh"

  touch "cwt/extensions/nftcwthdehnc/test/pre_nftcwthhnc_dry_run.hook.sh"
  touch "cwt/extensions/nftcwthdehnc/test/post_nftcwthhnc_dry_run.hook.sh"
  touch "cwt/extensions/nftcwthdehnc/test/post_nftcwthhnc_dry_run.$INSTANCE_TYPE.hook.sh"
  touch "cwt/extensions/nftcwthdehnc/test/post_nftcwthhnc_dry_run.$HOST_TYPE.hook.sh"
  touch "cwt/extensions/nftcwthdehnc/test/undo_nftcwthhnc_dry_run.$HOST_TYPE.$INSTANCE_TYPE.hook.sh"

  u_cwt_extend
}

##
# Will single action hooks load every matching files and none other ?
#
test_cwt_hook_single_action() {
  local hook_dry_run_matches=''
  local expected_list=''
  local s

  for s in $CWT_SUBJECTS; do
    case "$s" in bootstrap) continue ;; esac
    expected_list+="cwt/$s/nftcwthhnc_dry_run.hook.sh"$'\n'
  done
  expected_list+="cwt/extensions/nftcwthdehnc/instance/nftcwthhnc_dry_run.hook.sh
cwt/extensions/nftcwthdehnc/remote/nftcwthhnc_dry_run.hook.sh
cwt/extensions/nftcwthdehnc/test/nftcwthhnc_dry_run.$INSTANCE_TYPE.hook.sh
cwt/extensions/nftcwthdehnc/stack/nftcwthhnc_dry_run.hook.sh
"

  rm -f data/cwt/cache/hook.*nftcwthhnc*
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

  rm -f data/cwt/cache/hook.*nftcwthhnc*
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

  rm -f data/cwt/cache/hook.*nftcwthhnc*
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

  rm -f data/cwt/cache/hook.*nftcwthhnc*
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

  rm -f data/cwt/cache/hook.*nftcwthhnc*
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

  rm -f data/cwt/cache/hook.*nftcwthhnc*
  hook -a 'nftcwthhnc_dry_run' -s 'test' -v 'HOST_TYPE INSTANCE_TYPE' -p 'undo' -t

  u_test_compare_expected_lookup_paths
  u_test_lookup_paths_assertion "Prefix + combinatory variants filter hook test failed." $flag
}

##
# Cleans up any leftovers from previous tests.
#
oneTimeTearDown() {
  local s
  for s in $CWT_SUBJECTS; do
    case "$s" in bootstrap) continue ;; esac
    rm -f "cwt/$s/nftcwthhnc_dry_run.hook.sh"
  done
  rm -fr "cwt/extensions/nftcwthdehnc"
}

. cwt/vendor/shunit2/shunit2
