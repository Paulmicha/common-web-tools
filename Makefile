
##
# CWT main Makefile.
#
# By default, CWT will attempt to load the following includes if they exist, and
# silently fail if they don't.
#
# For convenience, make is used to produce shortcuts for operations and all
# arguments are automatically appended to commands using the following syntax.
# See https://stackoverflow.com/a/6273809/1826109 for details about this
# technique.
# @ path/to/my-script.sh $(filter-out $@,$(MAKECMDGOALS))
#
# Default CWT tasks are defined separately :
# @see cwt/default.mk
#

# The default task will be "instance init", shortened to just "init".
# @see cwt/default.mk
.DEFAULT_GOAL := init

# This '.env' file is generated during instance init.
-include .env

# Since the path to this project instance's scripts can be altered using a
# global, and since its value is only available after instance init has run, we
# attempt to include the default location if that global is not available yet.
ifndef PROJECT_SCRIPTS
-include scripts/cwt/extend/custom.mk
else
-include $(PROJECT_SCRIPTS)/cwt/extend/custom.mk
endif

ifdef CWT_MAKE_INC
-include $(CWT_MAKE_INC)
endif

# Default CWT tasks.
-include cwt/default.mk

# Automatically append arguments to tasks calls.
# @see https://stackoverflow.com/a/6273809/1826109
%:
	@:
