#!/usr/bin/env bash

##
# [abstract] Clears {{ COMPONENT }} {{ SERVICE }} using docker compose.
#
# This file is generated from template :
# @see {{ TEMPLATE }}
#
# @example
#   make {{ COMPONENT }}-{{ SERVICE }}-clear
#   # Or :
#   scripts/cwt/extend/{{ COMPONENT }}/{{ SERVICE }}_clear.sh
#

. cwt/bootstrap.sh

docker compose exec \
  -w "${{ COMPONENT }}_DOCROOT_C" \
  $DC_TTY \
  {{ COMPONENT }}-{{ SERVICE }} {{ CMD }}
