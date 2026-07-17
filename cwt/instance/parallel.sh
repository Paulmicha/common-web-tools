#!/usr/bin/env bash

##
# Unlogged parallel alias → thread/batch (`&` + wait).
#
# @example
#   make parallel e:transcribe-ogg e:transcribe-ocr
#   # Or :
#   cwt/instance/parallel.sh e:transcribe-ogg e:transcribe-ocr
#

# This is just an alias for :
. cwt/thread/batch.sh $@
