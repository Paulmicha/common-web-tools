#!/usr/bin/env bash

##
# Docker-compose stack restart action.
#
# @example
#   cwt/extensions/docker-compose/stack/rebuild.sh
#

. cwt/bootstrap.sh

docker-compose stop
sleep 1
docker-compose build
sleep 2
