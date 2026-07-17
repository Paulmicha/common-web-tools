#!/usr/bin/env bash

##
# List usable GPT models.
#
# @example
#   make gpt-pull
#   # Or :
#   cwt/extensions/gpt/gpt/pull.sh
#

. cwt/bootstrap.sh

u_hook_most_specific -s 'gpt' -a 'pull' -v 'HOST_OS HOST_TYPE INSTANCE_TYPE'
