#!/usr/bin/env bash

##
# CWT core global vars related tests.
#
# @requires cwt/vendor/shunit2
#
# This file may be dynamically executed.
# @see cwt/test/cwt.sh
#
# List of acronyms used (must not collide) :
# - nftcwtgevhnc = name for testing CWT global env vars hopefully not colliding
# - nftcwtgevdehnc = name for testing CWT global env vars dummy extension hopefully not colliding
#
# TODO test the different globals keys.
# @see global() in cwt/utilities/global.sh
#
# @example
#   cwt/test/cwt/global.test.sh
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
  local s_upper

  for s in $CWT_SUBJECTS; do
    u_str_uppercase "$s" 's_upper'
    cat > "cwt/$s/global.vars.sh" <<EOF
#!/usr/bin/env bash
global NFTCWTGEVHNC_VAR_CWT_$s_upper 'test'
EOF

    # Failsafe : cannot carry on if touch did not complete without error.
    if [[ $? -ne 0 ]]; then
      echo >&2
      echo "Error (2) in $BASH_SOURCE line $LINENO: cannot create temporary file for testing CWT globals." >&2
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

  mkdir -p "cwt/extensions/nftcwtgevdehnc/app"

  # Failsafe : cannot carry on without successful temporary extension dir creation.
  if [[ $? -ne 0 ]]; then
    echo >&2
    echo "Error (4) in $BASH_SOURCE line $LINENO: cannot create temporary extension dir for testing CWT globals." >&2
    echo "-> aborting" >&2
    echo >&2
    exit 4
  fi

  cat > "cwt/extensions/nftcwtgevdehnc/global.vars.sh" <<'EOF'
#!/usr/bin/env bash
global NFTCWTGEVHNC_VAR_1 'test'
EOF

  cat > "cwt/extensions/nftcwtgevdehnc/app/global.vars.sh" <<'EOF'
#!/usr/bin/env bash
global NFTCWTGEVHNC_APP_VAR_1 'test'
EOF

  # Forces detection of our newly created temporary extension.
  u_cwt_extend
}

##
# Does the initial aggregation process work ?
#
test_cwt_global_aggregate() {
  local global_lookup_paths=''
  local p_cwtii_dry_run=1
  local p_cwtii_yes=1
  local test_cwt_global_aggregate=1

  unset GLOBALS
  declare -A GLOBALS
  GLOBALS_COUNT=0
  GLOBALS_UNIQUE_NAMES=()
  GLOBALS_UNIQUE_KEYS=()

  u_global_aggregate
  # u_global_debug

  local s
  local s_upper
  local s_test_val
  for s in $CWT_SUBJECTS; do
    u_str_uppercase "$s" 's_upper'
    eval "s_test_val=\"\$NFTCWTGEVHNC_VAR_CWT_$s_upper\""
    assertEquals "Value of NFTCWTGEVHNC_VAR_CWT_$s_upper is missing or incorrect." "test" "$s_test_val"
  done

  assertEquals 'Value of NFTCWTGEVHNC_VAR_1 is missing or incorrect.' "test" "$NFTCWTGEVHNC_VAR_1"
  assertEquals 'Value of NFTCWTGEVHNC_APP_VAR_1 is missing or incorrect.' "test" "$NFTCWTGEVHNC_APP_VAR_1"
}

##
# Cleans up any leftovers from previous tests.
#
# (Internal shunit2 function called after all tests have run.)
#
oneTimeTearDown() {
  local s
  for s in $CWT_SUBJECTS; do
    rm -f "cwt/$s/global.vars.sh"
  done
  rm -fr 'cwt/extensions/nftcwtgevdehnc'
}

# Load and run shUnit2.
. cwt/vendor/shunit2/shunit2
