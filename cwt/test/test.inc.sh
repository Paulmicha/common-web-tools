#!/usr/bin/env bash

##
# Test-related utility functions.
#
# This file is sourced during core CWT bootstrap.
# @see cwt/bootstrap.sh
#
# Convention : functions names are all prefixed by "u" (for "utility").
#

##
# Custom hook test assertion helper.
#
# @param 1 String : failed test error message.
# @param 2 Int : numerical flag (error number).
#
# TODO [wip] @example
#
u_test_lookup_paths_assertion() {
  local p_msg="$1"
  local p_flag=$2
  local fail_reason

  case $flag in
    1) fail_reason='missing matching lookup paths' ;;
    2) fail_reason='too many matching lookup paths found' ;;
    *) fail_reason='unexpected error' ;;
  esac

  assertTrue "$p_msg (error $flag : $fail_reason)" "[ $flag -eq 0 ]"
}

##
# Custom hook expected result comparator helper.
#
# Writes result in the following variable in calling scope :
# @var flag
#
# @requires the following vars in calling scope :
# - hook_dry_run_matches
# - expected_list
#
# TODO [wip] implement proper params (instead of requiring
#   $hook_dry_run_matches + $expected_list vars in calling scope).
# TODO [wip] @example
#
u_test_compare_expected_lookup_paths() {
  local i
  local j
  local is_found

  local expected_count=0
  for i in $expected_list; do
    ((++expected_count))
  done

  local count_found=0
  for j in $hook_dry_run_matches; do
    ((++count_found))
  done

  flag=0

  for i in $expected_list; do
    is_found=0

    for j in $hook_dry_run_matches; do
      if [[ "$i" == "$j" ]]; then
        is_found=1
        break
      fi
    done

    if [[ $is_found -eq 0 ]]; then
      flag=1
      break
    fi
  done

  if [[ $flag -eq 0 ]] && [[ $count_found -ne $expected_count ]]; then
    flag=2
  fi
}

##
# True when result archiving is enabled.
#
u_test_results_enabled() {
  [[ "${CWT_TEST_RESULTS:-1}" != '0' ]]
}

##
# Begin archiving context for a batch run.
#
# @param $1 batch directory
# @param $2 [optional] partial : 1 = merge tree / append full-output (default 0)
#
u_test_results_batch_begin() {
  local p_dir="$1"
  local partial="${2:-0}"

  if ! u_test_results_enabled; then
    test_results_active=0
    return 0
  fi

  test_results_slug="${p_dir##*/}"
  test_results_active=1
  test_results_partial="$partial"
  test_results_tree_new=()

  mkdir -p data/test-results/frozen

  test_results_full_output_path="data/test-results/frozen/${test_results_slug}.full-output.txt"

  if [[ "$partial" -eq 1 ]]; then
    {
      echo
      echo "# --- partial run $(date -Iseconds) ---"
    } >>"$test_results_full_output_path"
  else
    : >"$test_results_full_output_path"
  fi

  if [[ "$partial" -eq 1 ]]; then
    local _summary_yml _summary_txt
    _summary_yml="data/test-results/test-${test_results_slug}.yml"
    _summary_txt="data/test-results/frozen/${test_results_slug}.txt"
    if [[ -f "$_summary_yml" ]]; then
      u_test_results_tree_load "$_summary_yml"
    elif [[ -f "$_summary_txt" ]]; then
      u_test_results_tree_load "$_summary_txt"
    else
      test_results_tree_loaded=()
    fi
  else
    test_results_tree_loaded=()
  fi

  return 0
}

##
# Load machine-readable tree lines from an existing summary file.
#
# @param $1 summary file path
#
u_test_results_tree_load() {
  local file="$1"
  local line key status current_suite case_name

  test_results_tree_loaded=()
  current_suite=''

  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ "$line" =~ ^# ]] && continue
    [[ -z "$line" ]] && continue
    [[ "$line" =~ ^(batch|updated|exit): ]] && continue
    [[ "$line" =~ ^cases:[[:space:]]*$ ]] && continue

    if [[ "$line" =~ ^([a-zA-Z0-9_]+):[[:space:]]*$ ]]; then
      current_suite="${BASH_REMATCH[1]}"
      continue
    fi

    if [[ "$line" =~ ^[[:space:]]+([^:]+):[[:space:]]*(PASS|FAIL|SKIP)[[:space:]]*$ ]]; then
      case_name="$(echo "${BASH_REMATCH[1]}" | xargs)"
      status="${BASH_REMATCH[2]}"
      if [[ "$case_name" == *.* ]]; then
        key="$case_name"
      elif [[ -n "$current_suite" ]]; then
        key="${current_suite}.${case_name}"
      else
        key="$case_name"
      fi
      test_results_tree_loaded+=("${key} ${status}")
      continue
    fi

    key="${line%% *}"
    status="${line#* }"
    test_results_tree_loaded+=("${key} ${status}")
  done <"$file"
}

##
# Record or replace one case line in the in-memory tree.
#
# @param $1 suite stem
# @param $2 case name (test_*)
# @param $3 status PASS|FAIL|SKIP
#
u_test_results_tree_put() {
  local suite="$1"
  local case_name="$2"
  local status="$3"
  local key="${suite}.${case_name}"
  local line="${key} ${status}"
  local i existing_key

  for i in "${!test_results_tree_new[@]}"; do
    existing_key="${test_results_tree_new[i]%% *}"

    if [[ "$existing_key" == "$key" ]]; then
      test_results_tree_new[i]="$line"
      return 0
    fi
  done

  test_results_tree_new+=("$line")
}

##
# Parse shunit2 suite stdout and write per-case archives.
#
# @param $1 suite stem
# @param $2 captured stdout file
#
u_test_results_parse_shunit_suite() {
  local suite="$1"
  local capture="$2"
  local test_dir case_name block status line
  local in_case=0
  local current_case=''

  if ! u_test_results_enabled || [[ "${test_results_active:-0}" -ne 1 ]]; then
    return 0
  fi

  test_dir=data/test-results/frozen

  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" =~ ^test_[a-zA-Z0-9_]+$ ]]; then
      if [[ -n "$current_case" ]]; then
        u_test_results_flush_case "$suite" "$current_case" "$block"
      fi

      current_case="$line"
      block="$line"$'\n'
      in_case=1

      continue
    fi

    if [[ "$in_case" -eq 1 ]]; then
      block+="$line"$'\n'

      if [[ "$line" =~ ^Ran\ [0-9]+\ test ]]; then
        :
      elif [[ "$line" == 'OK' || "$line" =~ ^FAILED ]]; then
        status='PASS'

        if [[ "$line" =~ ^FAILED ]]; then
          status='FAIL'
        elif echo "$block" | grep -qi 'skipped'; then
          status='SKIP'
        fi

        u_test_results_flush_case "$suite" "$current_case" "$block" "$status"

        current_case=''
        block=''
        in_case=0
      fi
    fi
  done <"$capture"

  if [[ -n "$current_case" ]]; then
    status='PASS'

    if echo "$block" | grep -q 'FAILED'; then
      status='FAIL'
    fi

    u_test_results_flush_case "$suite" "$current_case" "$block" "$status"
  fi
}

##
# Write one case output file and update tree.
#
u_test_results_flush_case() {
  local suite="$1"
  local case_name="$2"
  local block="$3"
  local status="${4:-PASS}"
  local out_file

  out_file="data/test-results/frozen/${test_results_slug}.${suite}.${case_name}.txt"
  printf '%s' "$block" >"$out_file"
  u_test_results_tree_put "$suite" "$case_name" "$status"
}

##
# Merge loaded + new tree entries and write human + machine summary.
#
# @param $1 batch exit code
#
u_test_results_batch_end() {
  local batch_exit="${1:-0}"
  local summary tree_file merged line key seen current_suite suite case_name status
  local -a all_lines=()

  if ! u_test_results_enabled || [[ "${test_results_active:-0}" -ne 1 ]]; then
    return 0
  fi

  tree_file="data/test-results/test-${test_results_slug}.yml"

  for line in "${test_results_tree_loaded[@]}"; do
    key="${line%% *}"
    seen="$seen $key "
    all_lines+=("$line")
  done

  for line in "${test_results_tree_new[@]}"; do
    key="${line%% *}"
    if [[ "$seen" == *" $key "* ]]; then
      local i existing_key
      for i in "${!all_lines[@]}"; do
        existing_key="${all_lines[i]%% *}"
        if [[ "$existing_key" == "$key" ]]; then
          all_lines[i]="$line"
        fi
      done
    else
      all_lines+=("$line")
      seen="$seen$key "
    fi
  done

  {
    echo "batch: ${test_results_slug}"
    echo "updated: $(date -Iseconds)"
    echo "exit: ${batch_exit}"
    current_suite=''
    while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      key="${line%% *}"
      status="${line#* }"
      suite="${key%%.*}"
      case_name="${key#*.}"
      if [[ "$suite" != "$current_suite" ]]; then
        echo "${suite}:"
        current_suite="$suite"
      fi
      echo "  ${case_name}: ${status}"
    done < <(printf '%s\n' "${all_lines[@]}" | sort)
  } >"$tree_file"

  rm -f "data/test-results/frozen/${test_results_slug}.txt"

  test_results_active=0
  return 0
}

##
# Read archived CLI case status for finish: mode.
#
# Echoes PASS, FAIL, SKIP, or MISSING.
#
# @param $1 batch slug
# @param $2 suite stem
# @param $3 case name (test_*)
#
u_test_results_case_status() {
  local slug="$1"
  local suite="$2"
  local case_name="$3"
  local key="${suite}.${case_name}"
  local tree_file line entry_key status current_suite case_stem in_suite=0

  tree_file="data/test-results/test-${slug}.yml"

  if [[ ! -f "$tree_file" ]]; then
    tree_file="data/test-results/frozen/${slug}.txt"
  fi

  if [[ ! -f "$tree_file" ]]; then
    echo 'MISSING'
    return 0
  fi

  current_suite=''

  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ "$line" =~ ^# ]] && continue
    [[ -z "$line" ]] && continue
    [[ "$line" =~ ^(batch|updated|exit): ]] && continue
    [[ "$line" =~ ^cases:[[:space:]]*$ ]] && continue

    if [[ "$line" =~ ^([a-zA-Z0-9_]+):[[:space:]]*$ ]]; then
      current_suite="${BASH_REMATCH[1]}"
      in_suite=0
      [[ "$current_suite" == "$suite" ]] && in_suite=1
      continue
    fi

    if [[ "$line" =~ ^[[:space:]]+([^:]+):[[:space:]]*(PASS|FAIL|SKIP)[[:space:]]*$ ]]; then
      entry_key="$(echo "${BASH_REMATCH[1]}" | xargs)"
      status="${BASH_REMATCH[2]}"

      if [[ "$entry_key" == *.* ]]; then
        if [[ "$entry_key" == "$key" ]]; then
          echo "$status"
          return 0
        fi
        continue
      fi

      if [[ "$in_suite" -eq 1 && "$entry_key" == "$case_name" ]]; then
        echo "$status"
        return 0
      fi

      continue
    fi

    entry_key="${line%% *}"

    if [[ "$entry_key" == "$key" ]]; then
      status="${line#* }"
      echo "${status:-MISSING}"
      return 0
    fi
  done <"$tree_file"

  echo 'MISSING'
}

##
# Write browser artifact tree summary under data/test-results/browser/.
#
# @param $1 kind headless|matrix|lighthouse
# @param $2 env id
#
u_test_results_write_browser_tree() {
  local kind="$1"
  local p_env="$2"
  local root dest summary

  root="$(data/test-results)/browser/${kind}/${p_env}"
  summary="$(data/test-results)/browser/${kind}/${p_env}.txt"

  mkdir -p "$(dirname "$summary")"

  {
    echo "# kind: ${kind}"
    echo "# env: ${p_env}"
    echo "# updated: $(date -Iseconds)"
    echo
    if [[ -d "$root" ]]; then
      find "$root" -type f | sort | sed "s|^${root}/||"
    fi
  } >"$summary"
}

##
# Resolve sibling batch directory from a batch action script path.
#
# @param $1 batch action script (e.g. scripts/cwt/extend/test/browser.sh)
# @param $2 [optional] output variable name (default: batch_dir)
#
u_test_batch_dir_from_script() {
  local batch_script="$1"
  local out_var="${2:-batch_dir}"
  local dir base result

  dir="${batch_script%/*}"
  base="${batch_script##*/}"
  base="${base%.sh}"
  result="${dir}/${base}"

  declare -g "${out_var}=${result}"
  echo "$result"
}

##
# Convert a test case stem to the dashed suffix used in make targets.
#
# @param $1 case stem (e.g. search_results)
#
u_test_case_stem_to_suffix() {
  local stem="$1"
  echo "${stem//_/-}"
}

##
# Build make target name for a batch task + case stem.
#
# @param $1 batch make task (e.g. test-browser)
# @param $2 case stem (e.g. impersonation)
#
u_test_case_make_target() {
  local batch_task="$1"
  local case_stem="$2"
  local suffix

  suffix="$(u_test_case_stem_to_suffix "$case_stem")"
  echo "${batch_task}-${suffix}"
}

##
# Path to optional custom case runner ({batch_dir}.case.sh).
#
# @param $1 batch directory
#
u_test_case_runner_path() {
  local batch_dir="$1"
  echo "${batch_dir}.case.sh"
}

##
# Read non-comment case stems from a .test-cases manifest.
#
# @param $1 manifest path
#
u_test_read_manifest_cases() {
  local manifest="$1"
  local stems=''
  local line

  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%%#*}"
    line="$(echo "$line" | xargs)"
    [[ -z "$line" ]] && continue
    stems+="$line "
  done <"$manifest"

  echo -n "$stems"
}

##
# Discover test cases for a batch action script.
#
# Writes: mode (flat|env_subdir|manifest), batch_dir, case_stems (space-separated).
# Returns 1 when no cases found.
#
# @param $1 batch action script path
#
u_test_discover_batch_cases() {
  local batch_script="$1"
  local batch_dir=''
  local manifest=''
  local p_env=''
  local stems=''
  local stem=''
  local found=0

  batch_dir="$(u_test_batch_dir_from_script "$batch_script")"

  if [[ ! -d "$batch_dir" ]]; then
    return 1
  fi

  manifest="${batch_dir}/.test-cases"
  if [[ -f "$manifest" ]]; then
    stems="$(u_test_read_manifest_cases "$manifest")"
    if [[ -n "$stems" ]]; then
      test_case_mode='manifest'
      test_case_batch_dir="$batch_dir"
      test_case_stems="$stems"
      return 0
    fi
  fi

  for p_env in $CWT_TEST_CASE_ENVS; do
    if [[ -d "${batch_dir}/${p_env}" ]]; then
      u_fs_file_list "${batch_dir}/${p_env}" '*.test.sh'
      for stem in $file_list; do
        stem="${stem%.test.sh}"
        [[ "$stem" == 'orchestrated' ]] && continue
        if ! u_str_contains_word "$stem" "$stems"; then
          stems+="$stem "
        fi
      done
      found=1
    fi
  done

  if [[ "$found" -eq 1 && -n "$stems" ]]; then
    test_case_mode='env_subdir'
    test_case_batch_dir="$batch_dir"
    test_case_stems="$stems"
    return 0
  fi

  u_fs_file_list "$batch_dir" '*.test.sh'
  for stem in $file_list; do
    stem="${stem%.test.sh}"
    [[ "$stem" == 'orchestrated' ]] && continue
    stems+="$stem "
  done

  if [[ -z "$stems" ]]; then
    return 1
  fi

  test_case_mode='flat'
  test_case_batch_dir="$batch_dir"
  test_case_stems="$stems"
  return 0
}

##
# Execute a single shunit2 test case file.
#
# @param $1 path to *.test.sh
#
u_test_file_exec() {
  local test_file="$1"
  local test_dir test_name exit_code

  if [[ ! -f "$test_file" ]]; then
    echo >&2
    echo "Error in u_test_file_exec() - $BASH_SOURCE line $LINENO: missing test file '$test_file'." >&2
    echo "-> Aborting." >&2
    echo >&2
    return 1
  fi

  if [[ "$test_file" != *.test.sh ]]; then
    echo >&2
    echo "Error in u_test_file_exec() - $BASH_SOURCE line $LINENO: '$test_file' is not a *.test.sh file." >&2
    echo "-> Aborting." >&2
    echo >&2
    return 1
  fi

  test_dir="${test_file%/*}"
  test_name="${test_file##*/}"

  echo "# Executing ${test_file} ..."

  if u_test_results_enabled && [[ "${test_results_active:-0}" -eq 1 ]]; then
    local tmp suite_stem
    tmp="$(mktemp)"
    suite_stem="${test_name%.test.sh}"

    "$test_file" 2>&1 | tee "$tmp" | tee -a "${test_results_full_output_path}"
    exit_code=${PIPESTATUS[0]}

    u_test_results_parse_shunit_suite "$suite_stem" "$tmp"
    rm -f "$tmp"
  else
    "$test_file"
    exit_code=$?
  fi

  if [[ "$exit_code" -ne 0 ]]; then
    echo >&2
    echo "The test case '$test_name' did not pass" >&2
    echo "-> aborting (see details above)." >&2
    echo >&2
    echo "# Executing ${test_file} : done."
    echo
    return "$exit_code"
  fi

  echo "# Executing ${test_file} : done."
  echo
  return 0
}

##
# Load generated test-case registry cache (if present).
#
u_test_case_cache_load() {
  if [[ "${test_case_registry_loaded:-0}" -eq 1 ]]; then
    return 0
  fi

  test_case_registry_targets=()
  test_case_registry_batch_tasks=()
  test_case_registry_stems=()
  test_case_registry_modes=()
  test_case_registry_batch_dirs=()
  test_case_registry_batch_scripts=()

  if [[ ! -f "$CWT_TEST_CASE_CACHE" ]]; then
    return 1
  fi

  # shellcheck disable=SC1090
  . "$CWT_TEST_CASE_CACHE"
  test_case_registry_loaded=1
  return 0
}

##
# Find registry row index for a make target name.
#
# @param $1 case make target (e.g. test-browser-impersonation)
# @param $2 [optional] output variable for index
#
u_test_case_registry_index() {
  local target="$1"
  local i=''

  u_test_case_cache_load || return 1

  for i in "${!test_case_registry_targets[@]}"; do
    if [[ "${test_case_registry_targets[i]}" == "$target" ]]; then
      echo "$i"
      return 0
    fi
  done

  return 1
}

##
# Run a single discovered test case for a batch.
#
# @param $1 batch make task
# @param $2 case stem
# @param $3 [optional] env id (env_subdir batches)
#
u_test_run_case() {
  local batch_task="$1"
  local case_stem="$2"
  local p_env="${3:-local}"
  local i='' mode='' batch_dir='' batch_script='' runner='' test_file=''
  local exit_code=0

  u_test_case_cache_load || true

  for i in "${!test_case_registry_targets[@]}"; do
    if [[ "${test_case_registry_batch_tasks[i]}" == "$batch_task" \
      && "${test_case_registry_stems[i]}" == "$case_stem" ]]; then
      mode="${test_case_registry_modes[i]}"
      batch_dir="${test_case_registry_batch_dirs[i]}"
      batch_script="${test_case_registry_batch_scripts[i]}"
      break
    fi
  done

  if [[ -z "$mode" ]]; then
    local make_entries=() real_scripts=()
    local j=''

    u_make_list_entry_points
    for j in "${!make_entries[@]}"; do
      if [[ "${make_entries[j]}" == "$batch_task" ]]; then
        batch_script="${real_scripts[j]}"
        break
      fi
    done

    if [[ -z "$batch_script" ]]; then
      echo >&2
      echo "Error in u_test_run_case() - unknown batch task '$batch_task'." >&2
      echo "-> Run make reinit to regenerate test-case targets." >&2
      echo >&2
      return 1
    fi

    u_test_discover_batch_cases "$batch_script" || return 1
    mode="$test_case_mode"
    batch_dir="$test_case_batch_dir"

    if ! u_str_contains_word "$case_stem" "$test_case_stems"; then
      echo >&2
      echo "Error in u_test_run_case() - unknown case '$case_stem' for batch '$batch_task'." >&2
      echo >&2
      return 1
    fi
  fi

  runner="$(u_test_case_runner_path "$batch_dir")"

  if u_test_results_enabled; then
    u_test_results_batch_begin "$batch_dir" 1
  fi

  case "$mode" in
    manifest)
      if [[ -x "$runner" || -f "$runner" ]]; then
        bash "$runner" "$p_env" "$case_stem"
        exit_code=$?
        if u_test_results_enabled && [[ "${test_results_active:-0}" -eq 1 ]]; then
          u_test_results_batch_end "$exit_code"
        fi
        return "$exit_code"
      fi
      echo >&2
      echo "Error in u_test_run_case() - manifest batch requires case runner: ${runner}" >&2
      echo >&2
      return 1
      ;;
    env_subdir)
      if [[ -f "$runner" ]]; then
        bash "$runner" "$p_env" "$case_stem"
        exit_code=$?
        if u_test_results_enabled && [[ "${test_results_active:-0}" -eq 1 ]]; then
          u_test_results_batch_end "$exit_code"
        fi
        return "$exit_code"
      fi
      test_file="${batch_dir}/${p_env}/${case_stem}.test.sh"
      u_test_file_exec "$test_file"
      exit_code=$?
      if u_test_results_enabled && [[ "${test_results_active:-0}" -eq 1 ]]; then
        u_test_results_batch_end "$exit_code"
      fi
      return "$exit_code"
      ;;
    flat)
      test_file="${batch_dir}/${case_stem}.test.sh"
      u_test_file_exec "$test_file"
      exit_code=$?
      if u_test_results_enabled && [[ "${test_results_active:-0}" -eq 1 ]]; then
        u_test_results_batch_end "$exit_code"
      fi
      return "$exit_code"
      ;;
    *)
      echo >&2
      echo "Error in u_test_run_case() - unknown mode '$mode'." >&2
      echo >&2
      return 1
      ;;
  esac
}

##
# Run a test case by its make target name.
#
# @param $1 case make target (e.g. test-browser-impersonation)
# @param $2 [optional] env id
#
u_test_run_case_by_target() {
  local target="$1"
  local p_env="${2:-local}"
  local i=''

  if ! u_test_case_cache_load; then
    echo >&2
    echo "Error in u_test_run_case_by_target() - missing ${CWT_TEST_CASE_CACHE}." >&2
    echo "-> Run make reinit to regenerate test-case targets." >&2
    echo >&2
    return 1
  fi

  for i in "${!test_case_registry_targets[@]}"; do
    if [[ "${test_case_registry_targets[i]}" == "$target" ]]; then
      u_test_run_case \
        "${test_case_registry_batch_tasks[i]}" \
        "${test_case_registry_stems[i]}" \
        "$p_env"
      return $?
    fi
  done

  echo >&2
  echo "Error in u_test_run_case_by_target() - unknown test-case target '$target'." >&2
  echo "-> Run make reinit to regenerate ${CWT_TEST_CASE_CACHE}" >&2
  echo >&2
  return 1
}

##
# Executes a series of tests dynamically loaded from given dir.
#
# @requires that the folder contains files using the double extension pattern :
# *.test.sh
#
# @param 1 String : path to folder containing test cases.
#
# @example
#   u_test_batch_exec cwt/extensions/mysql/test/mysql
#
u_test_batch_exec() {
  local p_dir="$1"
  local batch_exit=0

  if [[ ! -d "$p_dir" ]]; then
    echo >&2
    echo "Error in u_test_batch_exec() - $BASH_SOURCE line $LINENO: the '$p_dir' folder is missing or inaccessible." >&2
    echo "-> Aborting." >&2
    echo >&2
    exit 1
  fi

  u_test_results_batch_begin "$p_dir" 0

  u_fs_file_list "$p_dir" '*.test.sh'

  for test_script in $file_list; do
    u_test_file_exec "$p_dir/$test_script" || batch_exit=$?

    if [[ "$batch_exit" -ne 0 ]]; then
      break
    fi
  done

  u_test_results_batch_end "$batch_exit"

  return "$batch_exit"
}

##
# Tests if given program or alias is executable from current instance.
#
# @param $1 String : the program to test.
# @return Int : 0 if OK, or 1 if program was not found or not executable.
#
# @example
#   u_test_program_is_executable 'git'
#
u_test_program_is_executable() {
  local p_program="$1"
  local check=0

  if [[ "$(type -t $p_program)" == 'alias' ]]; then
    # TODO [fail] there seems to be no reliable way to test if an alias can run
    # successfully. Meanwhile, we assume that if an alias is found, it will be
    # executable.
    check=0
  elif ! [ -x "$(command -v $p_program)" ]; then
    check=1
  fi

  return $check
}

##
# Helper: true when word is in space-separated list.
#
u_str_contains_word() {
  local word="$1"
  local list="$2"
  case " $list " in
    *" $word "*) return 0 ;;
    *) return 1 ;;
  esac
}
