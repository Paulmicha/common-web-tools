#!/usr/bin/env bash

##
# Concurrent make steps (&) with wait barriers; exit = worst child.
#
# @param * String : e:<entry> [a:<arg> …] [workers:<N>] …
#
# @example
#   make thread-batch e:transcribe-all e:test-cwt
#   make parallel workers:2 e:a e:b e:c e:d
#   cwt/thread/batch.sh e:a e:b
#

. cwt/bootstrap.sh

if ! u_thread_parse_e_args "$@"; then
  echo >&2 "Aborting (1)."
  exit 1
fi

u_thread_run_batch
exit $?
