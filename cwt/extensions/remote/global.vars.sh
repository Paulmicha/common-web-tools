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

# CWT_REMOTE_FILES_SUFFIXES is used to build other variables, like :
# - REMOTE_INSTANCE_FILES_PUBLIC
# - REMOTE_INSTANCE_FILES_PRIVATE
# - etc.
# @see u_remote_instances_setup() in cwt/extensions/remote/remote.inc.sh

# This allows to have more control over the files to sync, without being tied to
# any specific implementation dealing with a particular app (e.g. Drupal,
# see the 'drupalwt' extension, i.e. sites/default/files).
# This is about remote interactions, which may not map well with the other
# "configurations".

# It can be overriden entirely, or more suffixes can be added like :
# $ global CWT_REMOTE_FILES_SUFFIXES "[append]=foobar"
# @see u_remote_definition_get_keys() in cwt/extensions/remote/remote.inc.sh
# @see cwt/extensions/remote/remote/files_dir_sync_from.sh

global CWT_REMOTE_FILES_SUFFIXES "[default]='public private'"


# TODO [wip] reevaluate and document where it is used. Currently :
# @see cwt/extensions/remote/remote/ssh_key_auth.sh
# Default path to the SSH public key to use for remote connections. This can be
# overridden per remote instance using the YAML file hook: remote_instances.yml
# @see u_remote_instances_setup() in cwt/extensions/remote/remote.inc.sh

global CWT_SSH_PUBKEY "[default]=$HOME/.ssh/id_rsa.pub"
