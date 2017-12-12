#!/usr/bin/env bash

##
# Php imagemagik setup.
#
# Tested on Debian 8.7 "Jessie"
# @timestamp 2017/07/02 17:49:15
#
# Run as root or sudo.
#

# Make sure this script only runs once per host.
eval `u_run_once_per_host "$BASH_SOURCE"`

apt install imagemagick -y
apt install php5-imagick -y
