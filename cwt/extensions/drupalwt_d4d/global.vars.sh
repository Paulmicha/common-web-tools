#!/usr/bin/env bash

##
# Global (env) vars for the 'drupalwt_d4d' CWT extension.
#
# This file is used during "instance init" to generate the global environment
# variables specific to current project instance.
#
# @see u_instance_init() in cwt/instance/instance.inc.sh
# @see cwt/utilities/global.sh
# @see cwt/bootstrap.sh
#

global D4D_BASIC_AUTH_USERS "[default]='$(u_str_basic_auth_credentials d4d_basic_auth_creds)' [help]='Http Basic Auth credentials for pubicly accessible services of remote instance whose type is “dev” or “stage”. Defauts to login : “admin”, and a randomly generated password that can be retrieved locally from a remote instance with the command : make remote-d4d-basic-auth (see cwt/extensions/drupalwt_d4d/remote/d4d_basic_auth.sh)'"
