#!/usr/bin/env bash

##
# Implements hook -s 'instance' -a 'uninit'.
#
# This implementation may optionally alter entries to the following var in
# calling scope :
#
# @var purge_list
#
# Cleans up any generated docker-compose.yml files.
# @see cwt/instance/uninit.sh
#
# @example
#   make uninit
#   # Or :
#   cwt/instance/uninit.sh
#

purge_list+=('docker-compose.yml')
purge_list+=('docker-compose.override.yml')
