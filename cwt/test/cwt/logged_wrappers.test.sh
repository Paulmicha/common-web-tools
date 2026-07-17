#!/usr/bin/env bash

##
# Smoke tests for log wrappers logged-chain (lc), logged-batch (lb), logged-pipe (lp).
#
# Parent observability = log/wrap flat capture under data/logs/<entry>.txt
# (+ changelog). Semantics for fail-fast / pipefail are covered on the
# unlogged runners where useful.
#
# @requires cwt/vendor/shunit2
#
# @example
#   cwt/test/cwt/logged_wrappers.test.sh
#   make test-cwt-logged-wrappers
#

. cwt/bootstrap.sh

# Extract PID from "Log started (PID N)." lines.
_u_test_log_pid() {
  local output="$1"
  echo "$output" | sed -n 's/.*PID \([0-9][0-9]*\).*/\1/p' | head -1
}

_u_test_wait_pid() {
  local pid="$1"
  local i

  [[ -n "$pid" ]] || return 1
  for i in $(seq 1 80); do
    if ! kill -0 "$pid" 2>/dev/null; then
      return 0
    fi
    sleep 0.25
  done
  return 1
}

oneTimeTearDown() {
  rm -f \
    data/logs/chain.txt \
    data/logs/chain.changelog.txt \
    data/logs/thread-batch.txt \
    data/logs/thread-batch.changelog.txt \
    data/logs/thread-pipe.txt \
    data/logs/thread-pipe.changelog.txt
}

test_logged_chain_parent_observability() {
  local output=''
  local exit_code=0
  local pid=''
  local marker="cwt-logged-wrappers-smoke-chain-$$"

  rm -f data/logs/chain.txt data/logs/chain.changelog.txt

  # Two quiet steps: make debug (echo.make.sh) via e:N: ordering.
  output="$(cwt/instance/logged_chain.sh \
    e:1:debug a:"${marker}-1" \
    e:2:debug a:"${marker}-2" 2>&1)" || exit_code=$?

  assertEquals 'logged_chain launcher must succeed' 0 "$exit_code"
  assertTrue 'announces Log started' "[[ '$output' == *'Log started'* ]]"
  assertTrue 'parent log path is data/logs/chain.txt' \
    "[[ '$output' == *'data/logs/chain.txt'* ]]"

  pid="$(_u_test_log_pid "$output")"
  assertTrue 'PID parsed' "[[ -n '$pid' ]]"
  assertTrue 'background chain finished' "_u_test_wait_pid '$pid'"

  assertTrue 'changelog exists' "[[ -f data/logs/chain.changelog.txt ]]"
  assertTrue 'output log exists' "[[ -f data/logs/chain.txt ]]"
  assertTrue 'changelog records chain.sh' \
    "grep -q 'cwt/instance/chain.sh' data/logs/chain.changelog.txt"
  assertTrue 'step 1 marker in parent log' \
    "grep -q '${marker}-1' data/logs/chain.txt"
  assertTrue 'step 2 marker in parent log' \
    "grep -q '${marker}-2' data/logs/chain.txt"
}

test_logged_batch_parent_observability() {
  local output=''
  local exit_code=0
  local pid=''
  local marker="cwt-logged-wrappers-smoke-batch-$$"

  rm -f data/logs/thread-batch.txt data/logs/thread-batch.changelog.txt

  output="$(cwt/instance/logged_batch.sh \
    e:debug a:"${marker}-a" \
    e:debug a:"${marker}-b" 2>&1)" || exit_code=$?

  assertEquals 'logged_batch launcher must succeed' 0 "$exit_code"
  assertTrue 'announces Log started' "[[ '$output' == *'Log started'* ]]"
  assertTrue 'parent log path is data/logs/thread-batch.txt' \
    "[[ '$output' == *'data/logs/thread-batch.txt'* ]]"

  pid="$(_u_test_log_pid "$output")"
  assertTrue 'PID parsed' "[[ -n '$pid' ]]"
  assertTrue 'background batch finished' "_u_test_wait_pid '$pid'"

  assertTrue 'changelog exists' \
    "[[ -f data/logs/thread-batch.changelog.txt ]]"
  assertTrue 'output log exists' "[[ -f data/logs/thread-batch.txt ]]"
  assertTrue 'changelog records batch.sh' \
    "grep -q 'cwt/thread/batch.sh' data/logs/thread-batch.changelog.txt"
  assertTrue 'branch a in parent log' \
    "grep -q '${marker}-a' data/logs/thread-batch.txt"
  assertTrue 'branch b in parent log' \
    "grep -q '${marker}-b' data/logs/thread-batch.txt"
}

test_logged_pipe_shell_stages_observability() {
  local output=''
  local exit_code=0
  local pid=''
  local marker="cwt-logged-wrappers-smoke-pipe-$$"

  rm -f data/logs/thread-pipe.txt data/logs/thread-pipe.changelog.txt

  output="$(cwt/instance/logged_pipe.sh \
    "echo ${marker}" \
    "grep ${marker}" 2>&1)" || exit_code=$?

  assertEquals 'logged_pipe launcher must succeed' 0 "$exit_code"
  assertTrue 'announces Log started' "[[ '$output' == *'Log started'* ]]"
  assertTrue 'parent log path is data/logs/thread-pipe.txt' \
    "[[ '$output' == *'data/logs/thread-pipe.txt'* ]]"

  pid="$(_u_test_log_pid "$output")"
  assertTrue 'PID parsed' "[[ -n '$pid' ]]"
  assertTrue 'background pipe finished' "_u_test_wait_pid '$pid'"

  assertTrue 'changelog exists' \
    "[[ -f data/logs/thread-pipe.changelog.txt ]]"
  assertTrue 'output log exists' "[[ -f data/logs/thread-pipe.txt ]]"
  assertTrue 'changelog records pipe.sh' \
    "grep -q 'cwt/thread/pipe.sh' data/logs/thread-pipe.changelog.txt"
  assertTrue 'piped marker in parent log' \
    "grep -q '${marker}' data/logs/thread-pipe.txt"
  assertFalse 'pipe must not show command-not-found' \
    "grep -q 'command not found' data/logs/thread-pipe.txt"
}

test_sequence_fail_fast() {
  local exit_code=0

  cwt/thread/sequence.sh e:__logged_wrappers_smoke_missing__ e:debug \
    >/dev/null 2>&1 || exit_code=$?

  assertNotEquals 'unknown first entry must fail' 0 "$exit_code"
}

test_sequence_join_semicolon_continues() {
  local output=''
  local exit_code=0
  local marker="cwt-logged-wrappers-join-$$"

  output="$(cwt/thread/sequence.sh 'join:;' \
    e:__logged_wrappers_smoke_missing__ \
    e:debug a:"${marker}" 2>&1)" || exit_code=$?

  assertNotEquals 'join:; still nonzero when a step fails' 0 "$exit_code"
  assertTrue 'second step still ran' "[[ '$output' == *'${marker}'* ]]"
}

. cwt/vendor/shunit2/shunit2
