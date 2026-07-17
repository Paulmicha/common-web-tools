#!/usr/bin/env bash

##
# For everything that writes things like :
# data/threads/<item>.yml
#
# This wrapper keeps a history of all the callers that CRUD above file :
# data/threads/<item>.sidecar.txt
#
# Applies to :
# - data/logs/<item>.txt -> data/logs/<item>.sidecar.txt
# - data/loops/<item>.yml -> data/loops/<item>.sidecar.txt
# - data/threads/<item>.yml -> data/threads/<item>.sidecar.txt
# - data/cronjobs/<item>.txt -> data/cronjobs/<item>.sidecar.txt
# - data/<memory_store>/<entity>.yml -> data/<memory_store>/<entity>.sidecar.txt
# - /etc/hosts -> /etc/hosts.sidecar.txt
#
# Also possible, maintain up to 7 sidecars for volatile storage like :
# data/gpt/<emitter>/<receiver>/YYYY/MM/DD/HH.MM.SS.MS.<item>.md
#   -> data/gpt/<emitter>/<receiver>/<item>.01.last_15m.sidecar.txt
#   -> data/gpt/<emitter>/<receiver>/<item>.02.last_1h.sidecar.txt
#   -> data/gpt/<emitter>/<receiver>/<item>.03.last_12h.sidecar.txt
#   -> data/gpt/<emitter>/<receiver>/<item>.04.last_24h.sidecar.txt
#   -> data/gpt/<emitter>/<receiver>/<item>.05.last_1w.sidecar.txt
#   -> data/gpt/<emitter>/<receiver>/<item>.06.last_1m.sidecar.txt
#   -> data/gpt/<emitter>/<receiver>/<item>.07.last_1y.sidecar.txt
#
# item can be a slugified_file_suffix :
# "path-to-cwt-action-or-hook_slugified-raw-args_underscore-separated"
# with a truncate at like 64 characters max.
#

. cwt/bootstrap.sh

# TODO
