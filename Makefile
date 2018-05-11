
##
# CWT main Makefile.
#
# This makefile is just a "hub" to optionally include any *.mk files found.
# @see cwt/env/current/README.md
#

-include .env

# TODO [wip] provide instance init by default in this "root" Makefile.

-include cwt/env/current/default.mk
-include $(CWT_MAKE_INC)
