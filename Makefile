
##
# CWT main Makefile.
#
# This is meant to be a "hub" including other *.mk files. It also attempts to
# load all the globals aggregated during instance init.
# @see cwt/env/current/README.md
#
# It provides the following tasks out of the box for all project instances :
# - [default] 'init': the 1st common step necessary to actually make CWT & its
#   extensions useful;
# - 'hook-call', a convenience wrapper to CWT hook() calls;
# - 'hook-debug', the same except it will just print out the lookup paths.
#   Useful for looking up positive matches to then provide overrides and/or
#   complements.
#
# @example
#   # Initialize current project instance = trigger "instance init" :
#   make
#   make init # <- Alternative call (the 'init' task is the default).
#
#   # Print lookup paths for the CWT hook call :
#   # hook -s 'instance' -a 'stop' -v 'PROVISION_USING HOST_TYPE'
#   make hook-debug s:instance a:stop v:PROVISION_USING HOST_TYPE
#
#   # Print result of the "most specific" hook call variant :
#   make hook-debug ms s:instance a:stop v:PROVISION_USING HOST_TYPE
#
#   # Trigger "instance start" manually :
#   make hook-call s:instance a:start
#

-include .env
-include cwt/env/current/default.mk
-include $(CWT_MAKE_INC)

default: init
.PHONY: init hook-call hook-debug

init:
	@ cwt/instance/init.sh $(filter-out $@,$(MAKECMDGOALS))

hook-call:
	@ cwt/instance/hook.mk.sh $(filter-out $@,$(MAKECMDGOALS))

hook-debug:
	@ cwt/instance/hook.mk.sh -d -t $(filter-out $@,$(MAKECMDGOALS))

# Automatically append arguments to tasks calls.
# @see https://stackoverflow.com/a/6273809/1826109
%:
	@:
