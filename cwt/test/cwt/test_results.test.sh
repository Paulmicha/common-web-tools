#!/usr/bin/env bash

##
# CWT core test : test results archiving helpers.
#
# @requires cwt/vendor/shunit2
#

. cwt/bootstrap.sh

test_results_self_tmp=''

oneTimeSetUp() {
  test_results_self_tmp="$(mktemp -d)"
  export CWT_TEST_RESULTS_ROOT="${test_results_self_tmp}/test-results"
  export CWT_TEST_RESULTS=1
}

oneTimeTearDown() {
  if [[ -n "$test_results_self_tmp" && -d "$test_results_self_tmp" ]]; then
    rm -rf "$test_results_self_tmp"
  fi
}

test_u_test_results_parse_shunit_suite() {
  local batch_dir capture suite_dir
  local tree_file

  batch_dir="${CWT_TEST_RESULTS_ROOT}/batch"
  mkdir -p "$batch_dir"
  capture="$(mktemp)"

  cat >"$capture" <<'EOF'
test_demo_one
line one

Ran 1 test.

OK
test_demo_two
assert failure

Ran 1 test.

FAILED (failures=1)
EOF

  u_test_results_batch_begin "$batch_dir" 0
  u_test_results_parse_shunit_suite 'demo' "$capture"
  u_test_results_batch_end 0

  assertTrue "missing case one output" \
    "[ -f '${CWT_TEST_RESULTS_ROOT}/test/batch.demo.test_demo_one.txt' ]"
  assertTrue "missing case two output" \
    "[ -f '${CWT_TEST_RESULTS_ROOT}/test/batch.demo.test_demo_two.txt' ]"

  tree_file="${CWT_TEST_RESULTS_ROOT}/test/batch.yml"
  assertTrue "missing tree file" "[ -f '${tree_file}' ]"
  grep -A5 '^demo:$' "$tree_file" | grep -q 'test_demo_one: PASS'
  assertEquals "case one should PASS" 0 "$?"
  grep -A5 '^demo:$' "$tree_file" | grep -q 'test_demo_two: FAIL'
  assertEquals "case two should FAIL" 0 "$?"

  rm -f "$capture"
}

test_u_freeze_tests_parse_subset_rejects_env_before_kind() {
  u_freeze_tests_parse_subset 'only:browser/preprod/headless' 2>/dev/null
  assertEquals "env-before-kind should fail" 1 "$?"
}

test_u_freeze_tests_parse_browser_headless_path() {
  freeze_tests_plan=()
  u_freeze_tests_parse_subset 'only:browser/headless/preprod/as-user'
  assertEquals "plan should have one item" 1 "${#freeze_tests_plan[@]}"
  assertEquals "plan item" 'browser:headless:preprod:as-user' "${freeze_tests_plan[0]}"
}

. cwt/vendor/shunit2/shunit2
