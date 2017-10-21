#!/bin/bash

##
# Install unattended security upgrades.
#
# Tested on Debian 8.7 "Jessie"
# @timestamp 2017/07/02 17:49:15
#
# Run as root or sudo.
#

apt install unattended-upgrades apt-listchanges -y
sed -e 's,\/\/Unattended-Upgrade::Mail "root";,Unattended-Upgrade::Mail "root";,g' -i /etc/apt/apt.conf.d/50unattended-upgrades
