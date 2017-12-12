#!/usr/bin/env bash

##
# NodeJS dev dependency install script - Debian.
#
# Tested on Debian 8.7 "Jessie"
# @timestamp 2017/09/21 22:07:24
#
# See https://github.com/creationix/nvm
#
# Usage :
# $ . cwt/provision/scripts/debian/8/nodejs_setup.sh
#

# Make sure this script only runs once per host.
eval `u_run_once_per_host "$BASH_SOURCE"`

wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.33.4/install.sh | bash
nvm install node
