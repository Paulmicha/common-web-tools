
##
# Default CWT tasks.
#
# Uses a "call wrap" script as an entry point to any other CWT script.
#
# @see cwt/make/call_wrap.make.sh
#
# It forwards escaped arguments to maintain the possibility to use values (in
# single quotes) with space, $, ", etc.
#
# Like :
# $ make drush ev '$test = "Hello Drupal php"; print $test;'
#
# By default, CWT provides the following tasks for all project instances :
# - [default] 'init': the 1st common step necessary to actually make CWT & its
#   extensions useful;
# - 'hook', a convenience wrapper to CWT hook() calls;
# - 'hook-debug', the same except it will just print out the lookup paths.
#   Useful for looking up positive matches to then provide overrides and/or
#   complements;
# - 'globals-lp', to show every globals lookup paths checked for aggregation
#   during instance init for current project instance;
# - 'self-test', to execute a few tests locally.
#
# @example
#   # Initialize current project instance = trigger "instance init" :
#   make
#   make init # <- Alternative call (the 'init' task is the default).
#
#   # Print lookup paths used for globals aggregation during instance init.
#   make globals-lp
#
#   # Print lookup paths for the CWT hook call :
#   # hook -s 'instance' -a 'stop' -v 'PROVISION_USING HOST_TYPE'
#   make hook-debug s:instance a:stop v:PROVISION_USING HOST_TYPE
#
#   # Print result of the "most specific" hook call variant :
#   make hook-debug ms s:instance a:stop v:PROVISION_USING HOST_TYPE
#
#   # Trigger "instance start" manually :
#   make hook s:instance a:start
#
#   # Print lookup paths for "instance start" using PROVISION_USING variant :
#   make hook-debug s:instance a:start v:PROVISION_USING
#   # Same but using more variants :
#   make hook-debug s:instance a:start v:PROVISION_USING HOST_TYPE INSTANCE_TYPE
#
#   # Trigger "test self_test" manually :
#   make self-test
#

.PHONY: init init-debug setup hook hook-debug globals-lp self-test debug
# .PHONY: init init-debug reinit setup hook hook-debug globals-lp self-test debug

init:
	@ cwt/make/call_wrap.make.sh cwt/instance/init.sh $(MAKECMDGOALS)

init-debug:
	@ cwt/make/call_wrap.make.sh cwt/instance/init.sh -d -r $(MAKECMDGOALS)

# TODO [evol] is this really overridden by scripts/cwt/local/generated.mk ?
# reinit:
# 	@ cwt/make/call_wrap.make.sh cwt/instance/reinit.sh $(MAKECMDGOALS)

setup:
	@ cwt/make/call_wrap.make.sh cwt/instance/setup.sh $(MAKECMDGOALS)

hook:
	@ cwt/make/call_wrap.make.sh cwt/instance/hook.make.sh $(MAKECMDGOALS)

hook-debug:
	@ cwt/make/call_wrap.make.sh cwt/instance/hook.make.sh -d -t $(MAKECMDGOALS)

globals-lp:
	@ cwt/make/call_wrap.make.sh cwt/env/global_lookup_paths.make.sh $(MAKECMDGOALS)

self-test:
	@ cwt/make/call_wrap.make.sh cwt/test/self_test.sh $(MAKECMDGOALS)

debug:
	@ echo "debug MAKECMDGOALS (unescaped, wrapped in single quotes) = '$(MAKECMDGOALS)'";
	@ cwt/make/call_wrap.make.sh cwt/make/echo.make.sh $(MAKECMDGOALS)
