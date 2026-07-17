#!/usr/bin/env bash

##
# List usable GPT models.
#
# @example
#   make gpt-list
#   # Or :
#   cwt/extensions/gpt/gpt/list.sh
#

. cwt/bootstrap.sh

u_hook_most_specific -s 'gpt' -a 'list' -v 'HOST_OS HOST_TYPE INSTANCE_TYPE'
