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

  # NB: aliases are not expanded when the shell is not interactive, unless the
  # expand_aliases shell option is set using shopt.
  # See https://unix.stackexchange.com/a/1498
  shopt -s expand_aliases

  # Include CWT core utilities.
  . cwt/utilities/shell.sh
  . cwt/utilities/cwt.sh
  . cwt/utilities/global.sh
  . cwt/utilities/hook.sh
  . cwt/utilities/autoload.sh
  . cwt/utilities/fs.sh
  . cwt/utilities/array.sh
  . cwt/utilities/string.sh
  . cwt/utilities/yaml.sh

  # If instance init was run at least once, automatically load locally generated
  # global env vars.
  # This can be opted-out by setting the flag CWT_BS_SKIP_GLOBALS to 1.
  # @see cwt/instance/init.sh
  if [[ $CWT_BS_SKIP_GLOBALS -ne 1 ]]; then
    if [[ -f scripts/cwt/local/global.vars.sh ]]; then
      . scripts/cwt/local/global.vars.sh
    fi
  fi

  # Initializes "primitives" for hooks and lookups (CWT extension mecanisms).
  # These are : subjects, actions, prefixes, variants and extensions.
  # Update 2024-06 cache results.
  if [[ -f scripts/cwt/local/cache/cwt.sh ]]; then
    . scripts/cwt/local/cache/cwt.sh
  else
    export cwt_primitives_cache_str=''
    CWT_INC=''
    u_cwt_extend
    mkdir -p scripts/cwt/local/cache
    cat > scripts/cwt/local/cache/cwt.sh <<CACHE
#!/usr/bin/env bash

##
# Generated cache file for CWT primitives.
#
# @see cwt/bootstrap.sh
#

$cwt_primitives_cache_str

CACHE
  fi

  # Because aliases are expanded when a function definition is read, *not* when
  # the function is executed, we need to have the possibility to define aliases
  # *before* the includes are sourced.
  # And because aliases may depend on optionally preset variables, we trigger
  # the "pre_bootstrap" hook before.
  # To verify which files can be used (and will be sourced) when these hooks are
  # triggered, use the following commands *in this order* :
  # $ make hook-debug s:cwt a:pre_bootstrap v:STACK_VERSION PROVISION_USING
  # $ make hook-debug s:cwt a:alias v:STACK_VERSION PROVISION_USING
  # $ make hook-debug s:cwt a:bootstrap v:STACK_VERSION PROVISION_USING
  hook -s 'cwt' -a 'pre_bootstrap' -v 'STACK_VERSION PROVISION_USING'
  hook -s 'cwt' -a 'alias' -v 'STACK_VERSION PROVISION_USING'

  # Load additional includes (including extensions').
  if [[ -n "$CWT_INC" ]]; then
    for file in $CWT_INC; do
      # Any additional include may be overridden.
      u_autoload_override "$file" 'continue'
      if [[ -n "$inc_override_evaled_code" ]]; then
        eval "$inc_override_evaled_code"
      fi
      if [[ -f "$file" ]]; then
        . "$file"
      fi
    done
  fi

  # Allow extensions to implement custom additional env. variables.
  hook -s 'cwt' -a 'bootstrap' -v 'STACK_VERSION PROVISION_USING'
fi
