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
# TODO [debt] Find better workaround to load PATH of required user. Currently :
#   su $p_user -c "my command (param 1)"
# -> avoid double quotes inside param 1 unless escaped (untested).
#
# @requires the 'crontab' software.
# See https://stackoverflow.com/a/17975418
#
# @param 1 String : the shell command to run.
# @param 2 [optional] String : crontab time - defaults to "every 30 minutes",
#   which is noted like : */30 * * * *
# @param 3 [optional] String : the user meant to run the script. Defaults to
#   current user - the one calling this function ($USER).
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
# Fractions like "*/5" mean "every 5 ..." (depending on position above).
#
# @example
#   # Run drupal cron task every 30 minutes (default) using current user (default) :
#   u_host_crontab_add "cd $PROJECT_DOCROOT && make drush cron"
#
#   # Run drupal cron task every 20 minutes as user 'www-data' :
#   u_host_crontab_add "cd $PROJECT_DOCROOT && make drush cron" '*/20 * * * *' 'www-data'
#
u_host_crontab_add() {
  local p_cmd="$1"
  local p_freq="$2"
  local p_user="$3"

  if [[ -z "$p_freq" ]]; then
    p_freq="*/30 * * * *"
  fi

  if [[ -z "$p_user" ]]; then
    p_user="$USER"
  fi

  # TODO [debt] find better workaround to run with PATH of required user loaded.
  # @see http://www.lostsaloon.com/technology/how-to-run-cron-jobs-as-a-specific-user/
  local cronjob="$p_freq su $p_user -c \"$p_cmd\""

  # See https://stackoverflow.com/a/17975418
  ( crontab -l | grep -v -F "$p_cmd" ; echo "$cronjob" ) | crontab -
}

##
# Removes a cronjob on local host.
#
# @requires the 'crontab' software.
# See https://stackoverflow.com/a/17975418
#
# @param 1 String : the shell command of the active cron job to remove. It
#   should match the one used in u_host_crontab_add() - i.e. no need to include
#   the user or frequency.
#
# @see u_host_crontab_add()
#
# @example
#   u_host_crontab_remove "cd $PROJECT_DOCROOT && make drush cron"
#
u_host_crontab_remove() {
  local p_cmd="$1"
  ( crontab -l | grep -v -F "$p_cmd" ) | crontab -
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
  os=$(u_str_slug "$os")
  version=$(u_str_slug "$version" '\.')

  # Prevent '-gnu-linux' in OS name.
  os=${os/-gnu-linux/""}

  echo "$os-$version" | tr '[:upper:]' '[:lower:]'
}

##
# [abstract] Sets host-level registry value.
#
# Writes to an abstract host-level storage by given key. "Abstract" means that
# CWT core itself doesn't provide any actual implementation for this
# functionality. It is necessary to use an extension which does. E.g. :
# @see cwt/extensions/file_registry
#
# @example
#   u_host_registry_set 'my_key' 1
#
u_host_registry_set() {
  local reg_key="$1"
  local reg_val=$2

  # Disallow empty keys.
  if [[ -z "$reg_key" ]]; then
    echo >&2
    echo "Error in u_host_registry_set() - $BASH_SOURCE line $LINENO: key is required." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    exit 1
  fi

  # Allows empty values (in which case this entry acts as a boolean flag).
  if [[ -z "$reg_val" ]]; then
    reg_val=1
  fi

  # NB : any implementation of this hook MUST use the reg_val and reg_key
  # variables (which are restricted to this function scope).
  u_hook_most_specific -s 'host' -a 'registry_set' -v 'HOST_TYPE'
}

##
# [abstract] Gets host-level registry value.
#
# Reads from an abstract host-level storage by given key. "Abstract" means that
# CWT core itself doesn't provide any actual implementation for this
# functionality. It is necessary to use an extension which does. E.g. :
# @see cwt/extensions/file_registry
#
# NB : for performance reasons (to avoid using a subshell), this function
# writes its result to a variable subject to collision in calling scope.
#
# @var reg_val
#
# @example
#   u_host_registry_get 'my_key'
#   echo "$reg_val" # <- Prints the value if there is an entry for 'my_key'.
#
u_host_registry_get() {
  local reg_key="$1"

  # Prevents risks of intereference between multiple calls (since we reuse the
  # same variable).
  unset reg_val

  # NB : any implementation of this hook MUST set its result using the reg_val
  # variable, in this case NOT restricted to this function scope.
  u_hook_most_specific -s 'host' -a 'registry_get' -v 'HOST_TYPE'
}

##
# [abstract] Deletes host-level registry value.
#
# Removes given entry from an abstract host-level storage by given key.
# "Abstract" means that CWT core itself doesn't provide any actual
# implementation for this functionality. It is necessary to use an extension
# which does. E.g. :
# @see cwt/extensions/file_registry
#
# @example
#   u_host_registry_del 'my_key'
#
u_host_registry_del() {
  local reg_key="$1"

  # NB : any implementation of this hook MUST use the reg_key variable (which is
  # restricted to this function scope).
  u_hook_most_specific -s 'host' -a 'registry_del' -v 'HOST_TYPE'
}

##
# Prevents running something more than once for entire host.
#
# Checks boolean flag for the entire local host.
# @see u_host_registry_get()
# @see u_host_registry_set()
#
# @example
#   # When you need to proceed inside the condition :
#   if u_host_once "my_once_id" ; then
#     echo "Proceed."
#   else
#     echo "Notice in $BASH_SOURCE line $LINENO : this has already been run on this host."
#     echo "-> Aborting."
#     exit
#   fi
#
#   # When you need to stop/exit inside the condition :
#   if ! u_host_once "my_once_id" ; then
#     echo "Notice in $BASH_SOURCE line $LINENO : this has already been run on this host."
#     echo "-> Aborting."
#     exit
#   fi
#
u_host_once() {
  local p_flag="$1"

  # TODO check what happens in case of unexpected collisions (if that var
  # already exists in calling scope).
  local reg_val

  u_host_registry_get "$p_flag"

  if [[ $reg_val -ne 1 ]]; then
    u_host_registry_set "$p_flag"
    return
  fi

  false
}
