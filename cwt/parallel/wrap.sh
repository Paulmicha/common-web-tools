#!/usr/bin/env bash

##
# Deprecated: use cwt/thread/batch.sh (make parallel / lb / thread-batch).
#
# This file is generated from template :
# @see cwt/extensions/preset/preset/parallel/wrap.tpl.sh
#
# Kept as a thin redirect so old call sites do not diverge from batch.
#

. cwt/thread/batch.sh "$@"
