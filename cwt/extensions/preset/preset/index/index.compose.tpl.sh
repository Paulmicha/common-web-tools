#!/usr/bin/env bash

##
# [abstract] Indexes {{ COMPONENT }} {{ SERVICE }} using docker compose.
#
# This file is generated from template :
# @see {{ TEMPLATE }}
#
# @example
#   make {{ COMPONENT }}-{{ SERVICE }}-index
#   # Or :
#   scripts/cwt/extend/{{ COMPONENT }}/{{ SERVICE }}_index.sh
#

. cwt/bootstrap.sh

docker compose exec \
  -w "${{ COMPONENT }}_DOCROOT_C" \
  $DC_TTY \
  {{ COMPONENT }}-{{ SERVICE }} {{ CMD }}
