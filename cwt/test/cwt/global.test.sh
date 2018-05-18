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
  for s in $CWT_SUBJECTS; do
    touch "cwt/$s/global.vars.sh"

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
  local inc
  local global_lookup_paths=''

  # TODO [wip] This is not possible to test the same way as cwt/test/cwt/hook.test.sh
  # u_global_lookup_paths
  # assertTrue 'Directory missing (creation test failed)' "[ -d '_cwt_dir_test' ]"
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
