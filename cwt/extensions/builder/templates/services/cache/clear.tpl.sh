#!/usr/bin/env bash

##
# [abstract] Triggers a generic hook to clear {{ COMPONENT }} {{ SERVICE }}.
#
# This file is generated from template :
# @see {{ TEMPLATE }}
#
# This script provides an entry point for triggering a specific hook. "Abstract"
# means that CWT core itself doesn't provide any actual implementation for this
# functionality. In order for this script to have any effect, it is necessary
# to use an extension that does.
#
# To list all the possible paths that can be used among which existing files
# will be sourced when the hook is triggered, run :
# $ make hook-debug s:{{ COMPONENT }} a:clear v:STACK_VERSION PROVISION_USING INSTANCE_TYPE
#
# @example
#   make {{ COMPONENT }}-{{ SERVICE }}-clear
#   # Or :
#   scripts/cwt/extend/{{ COMPONENT }}/{{ SERVICE }}_clear.sh
#

. cwt/bootstrap.sh

hook -p '{{ COMPONENT }}' -s '{{ SERVICE }}' -a 'clear' -v 'STACK_VERSION PROVISION_USING INSTANCE_TYPE'
