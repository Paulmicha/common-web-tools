#!/usr/bin/env bash

##
# Bootstraps CWT.
#
# Thin orchestrator: sources numbered phase includes under cwt/bootstrap/.
# Phases 10–70 run once per shell (CWT_BS_FLAG). Phase 90 (caller opt-inc)
# runs on every source so a second `. bootstrap` in an already-bootstrapped
# shell still loads the caller’s lazy helpers.
#
# Phase convention:
#   cwt/bootstrap/*.bootstrap-inc.sh — core phases only (not on CWT_INC)
# Eager includes:   $subject/$subject.inc.sh (and $ext/$ext.inc.sh) → CWT_INC
# Lazy (phase 90):  $subject/$subject.opt-inc.sh then $subject/$action.opt-inc.sh
#
# @example
#   . cwt/bootstrap.sh
#
# @see cwt/bootstrap/
#

# Make sure the heavy bootstrap runs only once in current shell scope.
if [[ $CWT_BS_FLAG -ne 1 ]]; then
  CWT_BS_FLAG=1

  . cwt/bootstrap/10-shell.bootstrap-inc.sh
  . cwt/bootstrap/20-utilities.bootstrap-inc.sh
  . cwt/bootstrap/30-globals.bootstrap-inc.sh
  . cwt/bootstrap/40-primitives.bootstrap-inc.sh
  . cwt/bootstrap/50-pre-hooks.bootstrap-inc.sh
  . cwt/bootstrap/60-includes.bootstrap-inc.sh
  . cwt/bootstrap/70-bootstrap-hook.bootstrap-inc.sh
fi

# Always: lazy-load optional includes for the bootstrap caller (subject + action).
_cwt_bs_caller=''
if [[ ${#BASH_SOURCE[@]} -gt 1 && -n "${BASH_SOURCE[1]}" ]]; then
  # BASH_SOURCE[0] is this file (bootstrap.sh); [1] is the real caller.
  _cwt_bs_caller="${BASH_SOURCE[1]}"
fi
. cwt/bootstrap/90-caller-opt-inc.bootstrap-inc.sh
unset _cwt_bs_caller
