
##
# CWT main Makefile.
#
# This makefile is just a "hub" to optionally include any *.mk files found.
# @see cwt/env/current/README.md
#

-include .env
-include cwt/env/current/default.mk
-include $(CWT_MAKE_INC)
