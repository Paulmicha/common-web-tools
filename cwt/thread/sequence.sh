#!/usr/bin/env bash

##
# Ordered make steps joined with && (default) or ;.
#
# @param * String : e:<entry> [a:<arg> …] [join:&&|;] …
#
# @example
#   make thread-sequence e:transcribe-all e:test-cwt
#   make chain join:; e:a e:b
#   cwt/thread/sequence.sh e:site-cr e:site-composer a:install e:api-cr
#

. cwt/bootstrap.sh

if ! u_thread_parse_e_args "$@"; then
  echo >&2 "Aborting (1)."
  exit 1
fi

u_thread_run_sequence
exit $?
