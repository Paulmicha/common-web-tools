#!/usr/bin/env bash

##
# Logged chain composition: log/wrap → instance/chain → thread/sequence.
#
# @example
#   # Manually hardcoded shortcut :
#   # @see CWT_SYNONYMS in cwt/env/global.vars.sh
#   make lc e:1:transcribe-ogg e:2:transcribe-ocr
#   # Equivalent to :
#   make logged-chain e:1:transcribe-ogg e:2:transcribe-ocr
#   # Or :
#   cwt/instance/logged_chain.sh e:1:transcribe-ogg e:2:transcribe-ocr
#

. cwt/bootstrap.sh

logged_chain_variants='STACK_VERSION PROVISION_USING HOST_OS'

hook -s 'log' -p 'pre' -a 'logged_chain' -v "$logged_chain_variants"
hook -s 'chain' -p 'pre' -a 'logged_chain' -v "$logged_chain_variants"

cwt/log/wrap.sh cwt/instance/chain.sh "$@"

hook -s 'log' -p 'post' -a 'logged_chain' -v "$logged_chain_variants"
hook -s 'chain' -p 'post' -a 'logged_chain' -v "$logged_chain_variants"
