#!/usr/bin/env bash

##
# [abstract] Triggers a generic 'logged thread' wrapped command.
#
# When you need observability for everyone with access to the local instance.
#
# This script provides an entry point for triggering a specific hook. "Abstract"
# means that CWT core itself doesn't provide any actual implementation for this
# functionality. In order for this script to have any effect, it is necessary
# to use an extension that does.
#
# The 'logged_thread' action triggers a 'pre'-prefixed hook before triggering the
# normal (unprefixed) hook. Same after ('post'-prefixed hook).
#
# To list all the possible paths that can be used among which existing files
# will be sourced when the hook is triggered, run (in this order) :
# $ make hook-debug s:log p:pre a:logged_thread v:STACK_VERSION HOST_TYPE INSTANCE_TYPE
# $ make hook-debug s:thread p:pre a:logged_thread v:STACK_VERSION HOST_TYPE INSTANCE_TYPE
# $ cwt/log/wrap.sh cwt/thread/wrap.sh $@
# $ make hook-debug s:log p:post a:logged_thread v:STACK_VERSION HOST_TYPE INSTANCE_TYPE
# $ make hook-debug s:thread p:post a:logged_thread v:STACK_VERSION HOST_TYPE INSTANCE_TYPE
#
# @example
#   # Manually hardcoded shortcut :
#   # @see CWT_MAKE_TASKS_SHORTER in cwt/env/global.vars.sh
#   make lt e:transcribe-all
#   # Equivalent to :
#   make logged-thread e:transcribe-all
#   # Or :
#   cwt/instance/logged_thread.sh transcribe-all
#

. cwt/bootstrap.sh

# Rewrite the 1st arg only if it contains our custom make prefix.
p_arg1="$1"
p_arg1=${p_arg1#'e:'}
set -- "$p_arg1" "${@:2}"

export LOGGED_THREAD_ENTRY="$p_arg1"

logged_thread_variants='STACK_VERSION PROVISION_USING HOST_OS'

# 1. Pre-process (log, then thread).
hook -s 'log' -p 'pre' -a 'logged_thread' -v "$logged_thread_variants"
hook -s 'thread' -p 'pre' -a 'logged_thread' -v "$logged_thread_variants"

# 2. Process (log, then thread).
. cwt/log/wrap.sh cwt/thread/wrap.sh $@

# 3. Post-process (log, then thread).
hook -s 'log' -p 'post' -a 'logged_thread' -v "$logged_thread_variants"
hook -s 'thread' -p 'post' -a 'logged_thread' -v "$logged_thread_variants"
