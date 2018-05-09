#!/usr/bin/env bash

##
# CWT core bootstrap-related tests.
#
# @requires cwt/vendor/shunit2
#
# This file may be dynamically executed.
# @see cwt/test/cwt.sh
#
# @example
#   cwt/test/cwt/bootstrap.test.sh
#

. cwt/bootstrap.sh

##
# Are all required CWT core globals successfully initialized ?
#
# @see u_cwt_extend()
#
test_cwt_has_essential_globals() {
  assertFalse 'Global CWT_SUBJECTS is empty (bootstrap test failed)' "[ -e $CWT_SUBJECTS ]"
  assertFalse 'Global CWT_ACTIONS is empty (bootstrap test failed)' "[ -e $CWT_ACTIONS ]"
  assertFalse 'Global CWT_INC is empty (bootstrap test failed)' "[ -e $CWT_INC ]"
}

##
# Does the 'complement' alteration mechanism work ?
#
test_cwt_autoload_complement_works() {
  local complement_flag
  local complement_source='cwt/test/self.sh'

  # Test without match.
  complement_flag=''
  u_autoload_get_complement "$complement_source"
  assertTrue 'Flag should be empty at this stage ("complement" alteration mechanism failed)' "[ -e $complement_flag ]"

  # Test with match (populates the local complement_flag variable).
  local base_dir='scripts'
  if [[ -n "$PROJECT_SCRIPTS" ]]; then
    base_dir="$PROJECT_SCRIPTS"
  fi
  mkdir -p "$base_dir/complements/test"
  cat > ${complement_source/cwt/"$base_dir/complements"} <<'EOF'
#!/usr/bin/env bash
complement_flag='not-empty'
EOF
  u_autoload_get_complement "$complement_source"
  assertFalse 'Flag should not be empty at this stage ("complement" alteration mechanism failed)' "[ -e $complement_flag ]"
}

##
# Does the 'override' alteration mechanism work ?
#
test_cwt_autoload_override_works() {
  local override_flag
  local override_source='cwt/test/self.sh'

  # Test without match.
  override_flag=''
  u_autoload_override "$override_source" 'override_flag="NOK"'
  eval "$inc_override_evaled_code"
  assertTrue 'Flag should be empty at this stage ("override" alteration mechanism failed)' "[ -e $override_flag ]"

  # Test with match (populates the local override_flag variable).
  local base_dir='scripts'
  if [[ -n "$PROJECT_SCRIPTS" ]]; then
    base_dir="$PROJECT_SCRIPTS"
  fi
  mkdir -p "$base_dir/overrides/test"
  cat > ${override_source/cwt/"$base_dir/overrides"} <<'EOF'
#!/usr/bin/env bash
override_flag='not-empty'
EOF
  u_autoload_override "$override_source" '# (we have to pass some inoperant code here to carry on with the test)'
  eval "$inc_override_evaled_code"
  assertFalse 'Flag should not be empty at this stage ("override" alteration mechanism failed)' "[ -e $override_flag ]"
}

##
# Cleans up any leftovers from previous tests.
#
# (Internal shunit2 function called after all tests have run.)
#
oneTimeTearDown() {
  local base_dir='scripts'
  if [[ -n "$PROJECT_SCRIPTS" ]]; then
    base_dir="$PROJECT_SCRIPTS"
  fi
  rm -rf "$base_dir/complements/test"
  rm -rf "$base_dir/overrides/test"
}

# Load and run shUnit2.
. cwt/vendor/shunit2/shunit2
