#!/usr/bin/env bash

##
# Diagnose existing CWT actions against preset conventions + hook dry-run tests.
#
# Inline report (fast):
#   - bash -n
#   - shebang, leading ##, . cwt/bootstrap.sh, @example with make + path
#   - registration via u_cwt_get_actions
#
# Hook dry-run (test-cwt): for abstract actions calling hook, ensure/generate a
# companion test under scripts/cwt/extend/test/preset/ from
# cwt/extensions/preset/preset/cwt/cwt/action.test.sh, then run that batch.
#
# @param ... [optional] : action script paths and/or subject/action pairs.
#   Default: all discovered actions under scripts/cwt/extend and cwt/ (except
#   vendor/utilities noise truncated to extend when no args).
#
# @example
#   make preset-improve
#   # Or :
#   cwt/extensions/preset/preset/improve.sh
#
#   make preset-improve scripts/cwt/extend/transcribe/all.sh
#   make preset-improve transcribe/all
#

. cwt/bootstrap.sh

preset_improve_fail=0
preset_improve_warn=0

u_preset_root || exit $?

##
# Report one check result.
#
_preset_improve_report() {
  local level="$1"
  local msg="$2"
  echo "[$level] $msg"
  case "$level" in
    FAIL) preset_improve_fail=$((preset_improve_fail + 1)) ;;
    WARN) preset_improve_warn=$((preset_improve_warn + 1)) ;;
  esac
}

##
# Resolve subject/action or path to a script file.
#
_preset_improve_resolve() {
  local p="$1"
  preset_improve_script=''

  if [[ -f "$p" ]]; then
    preset_improve_script="$p"
    return 0
  fi

  case "$p" in
    */*)
      if [[ -f "cwt/$p.sh" ]]; then
        preset_improve_script="cwt/$p.sh"
        return 0
      fi
      if [[ -f "scripts/cwt/extend/$p.sh" ]]; then
        preset_improve_script="scripts/cwt/extend/$p.sh"
        return 0
      fi
      ;;
  esac

  return 1
}

##
# Shape + registration checks for one action script.
#
_preset_improve_check_script() {
  local script="$1"
  local contents=''
  local sa=''
  local found=0
  local f

  echo "--- $script"

  if ! bash -n "$script" 2>/dev/null; then
    _preset_improve_report FAIL "$script: bash -n failed"
  else
    _preset_improve_report OK "$script: bash -n"
  fi

  u_fs_get_file_contents "$script" 'contents'

  if head -1 "$script" | grep -q '^#!'; then
    _preset_improve_report OK "$script: shebang"
  else
    _preset_improve_report WARN "$script: missing shebang"
  fi

  if grep -qE '^##' "$script"; then
    _preset_improve_report OK "$script: ## docblock"
  else
    _preset_improve_report WARN "$script: missing ## docblock"
  fi

  if grep -qE '\. cwt/bootstrap\.sh' "$script"; then
    _preset_improve_report OK "$script: bootstraps cwt"
  else
    _preset_improve_report FAIL "$script: missing . cwt/bootstrap.sh"
  fi

  if grep -q '@example' "$script"; then
    if grep -qE 'make [a-z0-9_-]+' "$script" && grep -qE '(cwt/|scripts/cwt/).*\.sh' "$script"; then
      _preset_improve_report OK "$script: @example has make + path"
    else
      _preset_improve_report WARN "$script: @example incomplete (want make + script path)"
    fi
  else
    _preset_improve_report WARN "$script: missing @example"
  fi

  # Registration (best-effort).
  u_cwt_get_actions
  found=0
  script_abs="$(cd "$(dirname "$script")" && pwd)/$(basename "$script")"
  for f in "${cwt_action_scripts[@]}"; do
    [[ -f "$f" ]] || continue
    f_abs="$(cd "$(dirname "$f")" && pwd)/$(basename "$f")"
    if [[ "$f_abs" == "$script_abs" ]]; then
      found=1
      break
    fi
  done

  if [[ $found -eq 1 ]]; then
    _preset_improve_report OK "$script: registered in CWT_ACTIONS"
  else
    _preset_improve_report WARN "$script: not found in u_cwt_get_actions (may need reinit or not an entry point)"
  fi

  # Generate hook dry-run test when abstract hook dispatch is present.
  if grep -qE '^\s*(hook|u_hook_most_specific)\s' "$script"; then
    _preset_improve_ensure_hook_test "$script"
  fi
}

##
# Ensure a companion hook dry-run test exists for an abstract action.
#
_preset_improve_ensure_hook_test() {
  local script="$1"
  local batch_dir='scripts/cwt/extend/test/preset'
  local base
  local dest
  local subject
  local action
  local hook_line
  local s_val=''
  local a_val=''
  local v_val='HOST_OS HOST_TYPE INSTANCE_TYPE'
  local test_fn

  mkdir -p "$batch_dir"

  base="$(basename "$script" .sh)"
  subject="$(basename "$(dirname "$script")")"
  action="$base"
  dest="$batch_dir/${subject}_${action}.test.sh"

  hook_line="$(grep -E '^\s*hook ' "$script" | head -1)"
  if [[ -n "$hook_line" ]]; then
    [[ "$hook_line" =~ -s[[:space:]]*[\'\"]?([^\'\"[:space:]]+) ]] && s_val="${BASH_REMATCH[1]}"
    [[ "$hook_line" =~ -a[[:space:]]*[\'\"]?([^\'\"[:space:]]+) ]] && a_val="${BASH_REMATCH[1]}"
    if [[ "$hook_line" =~ -v[[:space:]]*[\'\"]([^\'\"]+)[\'\"] ]]; then
      v_val="${BASH_REMATCH[1]}"
    fi
  fi

  [[ -z "$s_val" ]] && s_val="$subject"
  [[ -z "$a_val" ]] && a_val="$action"

  # Only generate when a hook already resolves on this host (avoids
  # mass-failing abstract stubs in test-cwt).
  hook_most_specific_dry_run_match=''
  u_hook_most_specific 'dry-run' -s "$s_val" -a "$a_val" -v "$v_val" -t
  if [[ ! -f "$hook_most_specific_dry_run_match" ]]; then
    _preset_improve_report WARN "$script: hook -s '$s_val' -a '$a_val' has no match on this host (skip test codegen)"
    return 0
  fi

  test_fn="test_${subject}_${action}_hook_resolves"

  cat > "$dest" <<EOF
#!/usr/bin/env bash

##
# Hook dry-run smoke for ${subject}/${action}.
#
# Generated by preset-improve from template conventions in
# cwt/extensions/preset/preset/cwt/cwt/action.test.sh
#
# @requires cwt/vendor/shunit2
#
# @example
#   ${dest}
#

. cwt/bootstrap.sh

${test_fn}() {
  u_hook_most_specific 'dry-run' -s '${s_val}' -a '${a_val}' -v '${v_val}' -t

  assertTrue '${s_val}/${a_val} hook must resolve on this host' "[[ -f '\$hook_most_specific_dry_run_match' ]]"
}

. cwt/vendor/shunit2/shunit2
EOF

  _preset_improve_report OK "$script: ensured hook test $dest"
  preset_improve_tests_dir="$batch_dir"
}

# --- main ---

preset_improve_explicit=0
if [[ $# -gt 0 ]]; then
  preset_improve_explicit=1
fi

targets=("$@")

if [[ ${#targets[@]} -eq 0 ]]; then
  # Default: extend entry points only (keeps runtime small).
  u_cwt_get_actions
  for f in "${cwt_action_scripts[@]}"; do
    case "$f" in
      scripts/cwt/extend/*)
        case "$f" in
          *.sh) targets+=("$f") ;;
        esac
        ;;
    esac
  done
fi

if [[ ${#targets[@]} -eq 0 ]]; then
  echo "No action scripts to improve."
  exit 0
fi

preset_improve_tests_dir=''

for t in "${targets[@]}"; do
  if ! _preset_improve_resolve "$t"; then
    _preset_improve_report WARN "cannot resolve target '$t'"
    continue
  fi
  _preset_improve_check_script "$preset_improve_script"
done

echo
echo "Summary: FAIL=$preset_improve_fail WARN=$preset_improve_warn"

# Run generated hook tests only for explicit targets (avoids mass-failing
# abstract hooks on a full extend scan). test-cwt still picks up the batch.
if [[ $preset_improve_explicit -eq 1 && -n "$preset_improve_tests_dir" && -d "$preset_improve_tests_dir" ]]; then
  echo
  echo "Running hook dry-run test batch: $preset_improve_tests_dir"
  u_test_batch_exec "$preset_improve_tests_dir" || preset_improve_fail=$((preset_improve_fail + 1))
elif [[ -n "$preset_improve_tests_dir" ]]; then
  echo
  echo "Hook tests updated under $preset_improve_tests_dir (run via make test-cwt or improve with explicit paths)."
fi

if [[ $preset_improve_fail -gt 0 ]]; then
  exit 1
fi
exit 0
