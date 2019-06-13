#!/usr/bin/env bash

##
# Global (env) vars for the 'remote' CWT extension.
#
# This file is used during "instance init" to generate the global environment
# variables specific to current project instance.
#
# @see u_instance_init() in cwt/instance/instance.inc.sh
# @see cwt/utilities/global.sh
# @see cwt/bootstrap.sh
#

# Default path to the SSH public key to use for remote connections. This can be
# overridden per remote instance using the YAML file hook: remote_instances.yml
# @see u_remote_instances_setup() in cwt/extensions/remote/remote.inc.sh
global CWT_SSH_PUBKEY "[default]=$HOME/.ssh/id_rsa.pub"
