#!/usr/bin/env bash

##
# Abstract local LLM bring-up: bootstrap → most-specific hook.
#
# @example
#   make gpt-start
#   # Or :
#   cwt/extensions/gpt/gpt/start.sh
#

. cwt/bootstrap.sh

u_hook_most_specific -s 'gpt' -a 'start' -v 'HOST_OS HOST_TYPE INSTANCE_TYPE'
