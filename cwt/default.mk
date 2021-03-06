
##
# Default CWT tasks.
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

.PHONY: default init init-debug hook hook-debug globals-lp self-test
default: init

init:
	@ cwt/instance/init.make.sh $(filter-out $@,$(MAKECMDGOALS))

init-debug:
	@ cwt/instance/init.make.sh -d -r $(filter-out $@,$(MAKECMDGOALS))

setup:
	@ cwt/instance/setup.sh $(filter-out $@,$(MAKECMDGOALS))

hook:
	@ cwt/instance/hook.make.sh $(filter-out $@,$(MAKECMDGOALS))

hook-debug:
	@ cwt/instance/hook.make.sh -d -t $(filter-out $@,$(MAKECMDGOALS))

globals-lp:
	@ cwt/env/global_lookup_paths.make.sh

list-actions:
	@ cwt/instance/list_actions.make.sh

self-test:
	@ cwt/test/self_test.sh
