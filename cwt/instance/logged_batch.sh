#!/usr/bin/env bash

##
# Logged batch composition: log/wrap → thread/batch.
#
# @example
#   # Manually hardcoded shortcut :
#   # @see CWT_SYNONYMS in cwt/env/global.vars.sh
#   make lb e:blueprint-generate e:transcribe-all
#   # Equivalent to :
#   make logged-batch e:blueprint-generate e:transcribe-all
#   # Or :
#   cwt/instance/logged_batch.sh e:blueprint-generate e:transcribe-all
#

. cwt/bootstrap.sh

logged_batch_variants='STACK_VERSION PROVISION_USING HOST_OS'

hook -s 'log' -p 'pre' -a 'logged_batch' -v "$logged_batch_variants"
hook -s 'batch' -p 'pre' -a 'logged_batch' -v "$logged_batch_variants"

cwt/log/wrap.sh cwt/thread/batch.sh "$@"

hook -s 'log' -p 'post' -a 'logged_batch' -v "$logged_batch_variants"
hook -s 'batch' -p 'post' -a 'logged_batch' -v "$logged_batch_variants"
