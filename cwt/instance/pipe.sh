#!/usr/bin/env bash

##
# Pipe composition alias → cwt/thread/pipe.sh (shell operator: |).
#
# @example
#   make pipe 'ls -lah' 'grep foobar'
#   make pipe e:transcribe-ogg e:transcribe-ocr
#   # Or :
#   cwt/instance/pipe.sh 'ls -lah' 'grep foobar'
#

. cwt/thread/pipe.sh "$@"
