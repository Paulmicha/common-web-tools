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
# Does the 'complement' extension mechanism work ?
#
test_cwt_autoload_complement_works() {
  local complement_flag
  local complement_source='cwt/test/self.sh'

  # Test without match.
  complement_flag=''
  u_autoload_get_complement "$complement_source"
  assertTrue 'Flag should be empty at this stage ("complement" autoload extension mechanism failed)' "[ -e $complement_flag ]"

  # Test with match (populates the local complement_flag variable).
  local base_dir='cwt/custom'
  if [[ -n "$CWT_CUSTOM_DIR" ]]; then
    base_dir="$CWT_CUSTOM_DIR"
  fi
  mkdir -p "$base_dir/complements/test"
  cat > ${complement_source/cwt/"$base_dir/complements"} <<'EOF'
#!/usr/bin/env bash
complement_flag='not-empty'
EOF
  u_autoload_get_complement "$complement_source"
  assertFalse 'Flag should not be empty at this stage ("complement" autoload extension mechanism failed)' "[ -e \"$complement_flag\" ]"
}

##
# Cleans up any leftovers from previous tests.
#
# (Internal shunit2 function called after all tests have run.)
#
oneTimeTearDown() {
  local base_dir='cwt/custom'
  if [[ -n "$CWT_CUSTOM_DIR" ]]; then
    base_dir="$CWT_CUSTOM_DIR"
  fi
  rm -rf "$base_dir/complements/test"
}

# Load and run shUnit2.
. cwt/vendor/shunit2/shunit2
