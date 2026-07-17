#!/usr/bin/env bash

##
# Abstract local LLM bring-up: bootstrap → most-specific hook.
#
# @example
#   make gpt-stop-all
#   # Or :
#   cwt/extensions/gpt/gpt/stop_all.sh
#

. cwt/bootstrap.sh

u_hook_most_specific -s 'gpt' -a 'stop_all' -v 'HOST_OS HOST_TYPE INSTANCE_TYPE'
