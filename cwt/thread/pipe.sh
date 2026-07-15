#!/usr/bin/env bash

##
# Join stages with a real shell pipe (|). pipefail; ≥2 stages.
#
# Stage kinds (colon prefixes only for structured tokens):
#   - positional string → bash -c -- "$stage"
#   - e:<entry>         → make <entry> [a: args…]
#   - a:<arg>           → arg for current make stage only
#
# @example
#   make pipe 'ls -lah' 'grep foobar'
#   make thread-pipe e:site-cr e:site-filter
#   make pipe e:site-composer a:install 'grep -i done'
#   cwt/thread/pipe.sh 'ls -lah' 'grep foobar'
#

. cwt/bootstrap.sh

if ! u_thread_parse_pipe_stages "$@"; then
  echo >&2 "Aborting (1)."
  exit 1
fi

u_thread_run_pipe
exit $?
