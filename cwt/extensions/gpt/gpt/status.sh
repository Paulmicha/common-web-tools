#!/usr/bin/env bash

##
# Abstract local LLM bring-up: bootstrap → most-specific hook.
#
# @example
#   make gpt-status
#   # Or :
#   cwt/extensions/gpt/gpt/status.sh
#

. cwt/bootstrap.sh

u_hook_most_specific -s 'gpt' -a 'status' -v 'HOST_OS HOST_TYPE INSTANCE_TYPE'
