#!/bin/bash

##
# Host-related utility functions.
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
  # Note : 'ip' command does not work on "Git bash" for Windows (but it works
  # on Windows 10 using "Bash on Ubuntu on Windows").
  # Yields bash: ip: command not found.
  ip route get 1 | awk '{print $NF;exit}'
}

##
# Returns host OS and its version.
#
# TODO Mac OS support.
#
# See https://unix.stackexchange.com/a/6348
#
u_host_get_os() {
  local os=''
  local version=''

  # freedesktop.org and systemd
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    os=$NAME
    version=$VERSION_ID
  # linuxbase.org
  elif type lsb_release >/dev/null 2>&1; then
    os=$(lsb_release -si)
    version=$(lsb_release -sr)
  # For some versions of Debian/Ubuntu without lsb_release command
  elif [ -f /etc/lsb-release ]; then
    . /etc/lsb-release
    os=$DISTRIB_ID
    version=$DISTRIB_RELEASE
  # Older Debian/Ubuntu/etc.
  elif [ -f /etc/debian_version ]; then
    os=Debian
    version=$(cat /etc/debian_version)
  # Older SuSE/etc.
  # elif [ -f /etc/SuSe-release ]; then
  # Older Red Hat, CentOS, etc.
  # elif [ -f /etc/redhat-release ]; then
  # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
  else
    os=$(uname -s)
    version=$(uname -r)
  fi

  # Prevent unexpected characters.
  os=$(u_slugify "$os")
  version=$(u_slugify "$version" '\.')

  echo "$os-$version" | tr '[:upper:]' '[:lower:]'
}
