#!/usr/bin/env bash

##
# Bootstrap phase: pre_bootstrap then alias hooks (before CWT_INC sources).
#
# Sourced only from cwt/bootstrap.sh (inside CWT_BS_FLAG).
#
# @see cwt/bootstrap.sh
#

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
