#!/bin/bash

##
# Network-related utility functions.
#
# This script is dynamically loaded.
# @see cwt/bash_utils.sh
#
# Convention : functions names are all prefixed by "u" (for "utility").
#

##
# Returns current host IP address.
#
# See https://stackoverflow.com/a/25851186
#
u_get_localhost_ip() {
  ip route get 1 | awk '{print $NF;exit}'
}
