#!/usr/bin/env bash

##
# Global (env) vars for the 'apache' CWT extension.
#
# This file is used during "instance init" to generate the global environment
# variables specific to current project instance.
#
# @see u_instance_init() in cwt/instance/instance.inc.sh
# @see cwt/utilities/global.sh
# @see cwt/bootstrap.sh
#

global CWT_APACHE_INIT_VHOST "[default]=true [help]='Set to « true » to automatically generate a vhost definition for this instance during instance init.'"
