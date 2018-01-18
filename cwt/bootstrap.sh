#!/usr/bin/env bash

##
# Bootstraps CWT.
#
# Loads includes containing bash functions along with readonly global vars if
# available, initializes "primitives" for hooks and lookups (CWT extension
# mecanisms), and call 'bootstrap' hook (i.e. to load bash aliases).
#
# @example
#   . cwt/bootstrap.sh
#

# Make sure bootstrap runs only once in current shell scope.
if [[ -z "$cwt_bs_flag" ]]; then
  cwt_bs_flag=1

  # Include "core" utilities.
  . "cwt/utilities/array.sh"
  . "cwt/utilities/autoload.sh"
  . "cwt/utilities/cwt.sh"
  . "cwt/utilities/fs.sh"
  . "cwt/utilities/global.sh"
  . "cwt/utilities/hook.sh"
  . "cwt/utilities/host.sh"
  . "cwt/utilities/instance.sh"
  . "cwt/utilities/once.sh" # TODO remove or make opt-in.
  . "cwt/utilities/registry.sh" # TODO remove or make opt-in.
  . "cwt/utilities/string.sh"

  # If stack init was run at least once, automatically load global env vars.
  # NB : this must happen before u_cwt_extend() gets called because it uses the
  # customizable global var CWT_CUSTOM_DIR to populate primitive values.
  if [[ -f "cwt/env/current/global.vars.sh" ]]; then
    . cwt/env/load.sh
  fi

  # Initializes "primitives" for hooks and lookups (CWT extension mecanisms).
  # These are : subjects, actions, prefixes, variants and extensions.
  u_cwt_extend

  # Load additional includes (including extensions').
  if [[ -n "$CWT_INC" ]]; then
    for file in $CWT_INC; do
      . "$file"
      # Any additional include may be altered using the 'complement' pattern.
      u_autoload_get_complement "$file"
    done
  fi

  # Bash aliases should be loaded by implementing the 'bootstrap' action hook.
  # NB: aliases are not expanded when the shell is not interactive, unless the
  # expand_aliases shell option is set using shopt.
  # See https://unix.stackexchange.com/a/1498
  shopt -s expand_aliases
  hook -a 'bootstrap'
fi
