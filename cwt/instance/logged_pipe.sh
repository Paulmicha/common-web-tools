#!/usr/bin/env bash

##
# Logged pipe composition: log/wrap → thread/pipe (|).
#
# Stages may be shell command strings and/or make entries (e:).
#
# @example
#   # Manually hardcoded shortcut :
#   # @see CWT_SYNONYMS in cwt/env/global.vars.sh
#   make lp e:blueprint-generate e:transcribe-all
#   # Equivalent to :
#   make logged-pipe e:blueprint-generate e:transcribe-all
#   # Or :
#   cwt/instance/logged_pipe.sh e:blueprint-generate e:transcribe-all
#

. cwt/bootstrap.sh

logged_pipe_variants='STACK_VERSION PROVISION_USING HOST_OS'

hook -s 'log' -p 'pre' -a 'logged_pipe' -v "$logged_pipe_variants"
hook -s 'pipe' -p 'pre' -a 'logged_pipe' -v "$logged_pipe_variants"

cwt/log/wrap.sh cwt/thread/pipe.sh "$@"

hook -s 'log' -p 'post' -a 'logged_pipe' -v "$logged_pipe_variants"
hook -s 'pipe' -p 'post' -a 'logged_pipe' -v "$logged_pipe_variants"
