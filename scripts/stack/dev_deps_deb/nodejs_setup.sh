#!/bin/bash

##
# NodeJS dev dependency install script - Debian.
#
# Tested on Debian 8.7 "Jessie"
# @timestamp 2017/09/21 22:07:24
#
# See https://github.com/creationix/nvm
# Run as root or sudo from dev stack docroot.
#
# Usage :
# $ . scripts/stack/dev_deps_deb/nodejs_setup.sh
#

# Run once per host.
wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.33.4/install.sh | bash
nvm install node
