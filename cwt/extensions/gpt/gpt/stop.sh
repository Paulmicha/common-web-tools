#!/usr/bin/env bash

##
# Abstract local LLM bring-up: bootstrap → most-specific hook.
#
# @example
#   make gpt-stop
#   # Or :
#   cwt/extensions/gpt/gpt/stop.sh
#

. cwt/bootstrap.sh

u_hook_most_specific -s 'gpt' -a 'stop' -v 'HOST_OS HOST_TYPE INSTANCE_TYPE'
