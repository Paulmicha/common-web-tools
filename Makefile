
##
# CWT main Makefile.
#
# Make is used not as a compiling tool here. It provides memorable shortcuts.
# A wrapper script is used to forward arguments to CWT action scripts.
#
# By default, CWT will attempt to load the following includes if they exist, and
# silently fail if they don't.
#

# The default task will be "instance init", shortened to just "init".
# @see cwt/make/default.mk
.DEFAULT_GOAL := init

# These files are automatically generated during instance init.
-include .env
-include scripts/cwt/local/generated.mk

# Project-specific tasks.
ifdef CWT_MAKE_INC
-include $(CWT_MAKE_INC)
endif
-include scripts/cwt/extend/custom.mk

# Default CWT tasks.
-include cwt/make/default.mk

# Automatically append arguments to tasks calls.
# @see https://stackoverflow.com/a/6273809/1826109
%:
	@:
