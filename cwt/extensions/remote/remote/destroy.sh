#!/usr/bin/env bash

##
# CWT remote instance destroy action.
#
# This will :
# - stop all running services on given remote instance host
# - destroy associated Docker volumes and networks
# - physically remove everything inside PROJECT_DOCROOT of given remote instance
#
# @example
#   make remote-destroy 'my_short_id'
#   # Or :
#   cwt/extensions/remote/remote/destroy.sh 'my_short_id'
#

. cwt/bootstrap.sh

cwt/extensions/remote/remote/exec.sh "$1" \
  'cwt/instance/destroy.sh && find . -delete'
