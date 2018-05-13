#!/usr/bin/env bash

##
# CWT remote instance add action.
#
# @example
#   cwt/remote/instance_add.sh \
#     'my_short_id' \
#     'remote.instance.example.com' \
#     'stage' \
#     'my_ssh_user' \
#     '/path/to/remote/instance/docroot'
#

. cwt/bootstrap.sh
u_remote_instance_add "$@"
