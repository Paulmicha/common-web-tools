
##
# CWT main Makefile.
#
# This makefile is just a "hub" to optionally include any *.mk files found.
# @see cwt/env/current/README.md
#

-include .env
-include cwt/env/current/default.mk
-include $(CWT_MAKE_INC)

# By default, always provide (instance) init action.
.PHONY: init
default: init
init:
	@ cwt/instance/init.sh $(filter-out $@,$(MAKECMDGOALS))

# Automatically append arguments to make calls.
# @see https://stackoverflow.com/a/6273809/1826109
%:
	@:
