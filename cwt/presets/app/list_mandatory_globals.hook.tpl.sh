#!/usr/bin/env bash

##
# Implements hook -s '{{ COMPONENT }}' -a 'list_mandatory_globals' -v 'STACK_VERSION PROVISION_USING INSTANCE_TYPE'.
#
# This file is generated from template :
# @see {{ TEMPLATE }}
#
# Uses the following var in calling scope :
# @var mandatory_globals
#
# This file is dynamically included when the "hook" is triggered.
# @see cwt/bootstrap.sh
#
# To list all the possible paths that can be used among which existing files
# will be sourced when the hook is triggered, run :
# $ make hook-debug s:{{ COMPONENT }} a:list_mandatory_globals v:STACK_VERSION PROVISION_USING INSTANCE_TYPE
#

mandatory_globals+=('{{ COMPONENT }}_DOCROOT')
