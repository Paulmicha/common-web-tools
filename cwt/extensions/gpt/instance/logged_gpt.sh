#!/usr/bin/env bash

##
# Logged gpt composition: log/wrap → thread/gpt.
#
# @example
#   make logged-gpt e:blueprint-generate e:transcribe-all
#   # Or :
#   cwt/instance/logged_gpt.sh e:blueprint-generate e:transcribe-all
#

. cwt/bootstrap.sh

logged_gpt_variants='STACK_VERSION PROVISION_USING HOST_OS'

hook -s 'log' -p 'pre' -a 'logged_gpt' -v "$logged_gpt_variants"
hook -s 'gpt' -p 'pre' -a 'logged_gpt' -v "$logged_gpt_variants"

cwt/log/wrap.sh cwt/extensions/gpt/gpt/wrap.sh "$@"

hook -s 'log' -p 'post' -a 'logged_gpt' -v "$logged_gpt_variants"
hook -s 'gpt' -p 'post' -a 'logged_gpt' -v "$logged_gpt_variants"
