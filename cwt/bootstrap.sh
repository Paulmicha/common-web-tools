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
if [[ $CWT_BS_FLAG -ne 1 ]]; then
  CWT_BS_FLAG=1

  # Include CWT core utilities.
  . cwt/utilities/cwt.sh
  . cwt/utilities/global.sh
  . cwt/utilities/hook.sh
  . cwt/utilities/autoload.sh
  . cwt/utilities/fs.sh
  . cwt/utilities/array.sh
  . cwt/utilities/string.sh

  # If instance init was run at least once, automatically load global env vars.
  # NB : this must happen before u_cwt_extend() gets called because it uses the
  # customizable global var PROJECT_SCRIPTS to populate primitive values.
  # This can be opted-out by setting the flag CWT_BS_SKIP_GLOBALS to 1.
  # @see cwt/instance/init.sh
  if [[ -f "cwt/env/current/global.vars.sh" ]] && [[ $CWT_BS_SKIP_GLOBALS -ne 1 ]]; then
    . cwt/env/current/global.vars.sh
  fi

  # Initializes "primitives" for hooks and lookups (CWT extension mecanisms).
  # These are : subjects, actions, prefixes, variants and extensions.
  CWT_INC=''
  u_cwt_extend

  # Load additional includes (including extensions').
  if [[ -n "$CWT_INC" ]]; then
    for file in $CWT_INC; do
      # Any additional include may be overridden.
      u_autoload_override "$file" 'continue'
      eval "$inc_override_evaled_code"

      . "$file"

      # Any additional include may be altered using the 'complement' pattern.
      u_autoload_get_complement "$file"
    done
  fi

  # Allow extensions to implement custom global variables or aliases.
  # To verify which files can be used (and will be sourced) when these hooks are
  # triggered, use the following commands in this order :
  # $ make hook-debug s:cwt a:pre_bootstrap v:PROVISION_USING
  # $ make hook-debug s:cwt a:bootstrap v:PROVISION_USING
  # NB: aliases are not expanded when the shell is not interactive, unless the
  # expand_aliases shell option is set using shopt.
  # See https://unix.stackexchange.com/a/1498
  shopt -s expand_aliases
  hook -s 'cwt' -a 'pre_bootstrap' -v 'PROVISION_USING'
  hook -s 'cwt' -a 'bootstrap' -v 'PROVISION_USING'
fi
