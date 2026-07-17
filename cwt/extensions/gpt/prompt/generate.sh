#!/usr/bin/env bash

##
# [abstract] Triggers a generic 'prompt generate' wrapped command.
#
# @example
#   make prompt-generate $(cwt/escape.sh 'Hello "world".')
#   # Or :
#   cwt/instance/prompt_generate.sh 'Hello "world".'
#

. cwt/bootstrap.sh

prompt_generate_variants='STACK_VERSION PROVISION_USING HOST_OS'

hook -s 'log' -p 'pre' -a 'prompt_generate' -v "$prompt_generate_variants"
hook -s 'gpt' -p 'pre' -a 'prompt_generate' -v "$prompt_generate_variants"

. cwt/extensions/gpt/gpt/wrap.sh "$@"

hook -s 'log' -p 'post' -a 'prompt_generate' -v "$prompt_generate_variants"
hook -s 'gpt' -p 'post' -a 'prompt_generate' -v "$prompt_generate_variants"
