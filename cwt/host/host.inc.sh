#!/usr/bin/env bash

##
# Host-related utility functions.
#
# This file is sourced during core CWT bootstrap.
# @see cwt/bootstrap.sh
#
# Convention : functions names are all prefixed by "u" (for "utility").
#

##
# Adds (once) a cronjob on local host.
#
# @requires the 'crontab' software.
# See https://stackoverflow.com/a/17975418
#
# @param 1 String the shell command to run.
# @param 2 [optional] String crontab time - defaults to "every 30 minutes" which
#   is noted like : */30 * * * *
#
# Quick crontab syntax notes :
#
#   * * * * *
#   | | | | |
#   | | | | +----- day of week (0 - 6) (Sunday=0)
#   | | | +------- month (1 - 12)
#   | | +--------- day of month (1 - 31)
#   | +----------- hour (0 - 23)
#   +------------- min (0 - 59)
#
# Numbers like 10 mean "at the 10th ..." (depending on position above).
# Fractions like "0/5" mean "every 5 ..." (depending on position above).
#
# @example
#   # Run drupal cron task every 20 minutes :
#   u_host_cron_add "drush --root=$APP_DOCROOT cron" "*/20 * * * *"
#
u_host_cron_add() {
  local p_cmd="$1"
  local p_freq="$2"

  if [[ -z "$p_freq" ]]; then
    p_freq="*/30 * * * *"
  fi

  local cronjob="$p_freq $p_cmd"

  # See https://stackoverflow.com/a/17975418
  ( crontab -l | grep -v -F "$p_cmd" ; echo "$cronjob" ) | crontab -
}

##
# Returns current host IP address.
#
# See https://stackoverflow.com/a/25851186
#
u_host_ip() {
  # Note : 'ip' command does not work on "Git bash" for Windows (but it works
  # on Windows 10 using "Bash on Ubuntu on Windows").
  # Yields bash: ip: command not found.
  ip route get 1 | awk '{print $NF;exit}'
}

##
# Returns host OS and its version.
#
# TODO [evol] Mac OS support ?
#
# See https://unix.stackexchange.com/a/6348
#
u_host_os() {
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

  # Prevent '-gnu-linux' in OS name.
  os=${os/-gnu-linux/""}

  echo "$os-$version" | tr '[:upper:]' '[:lower:]'
}
