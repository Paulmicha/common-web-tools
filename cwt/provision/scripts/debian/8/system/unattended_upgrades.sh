#!/bin/bash

##
# Install unattended security upgrades.
#
# Tested on Debian 8.7 "Jessie"
# @timestamp 2017/07/02 17:49:15
#
# Run as root or sudo.
#

# Make sure this script only runs once per host.
eval `u_run_once_per_host "$BASH_SOURCE"`

apt install unattended-upgrades apt-listchanges -y
sed -e 's,\/\/Unattended-Upgrade::Mail "root";,Unattended-Upgrade::Mail "root";,g' -i /etc/apt/apt.conf.d/50unattended-upgrades
