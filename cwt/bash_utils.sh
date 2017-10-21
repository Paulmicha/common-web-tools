#!/bin/bash

##
# Bash scripts utilities.
#
# Convention : fonctions names are all prefixed by "u" (for "utility").
#
# Load from project root dir :
# $ . cwt/bash_utils.sh
#

##
# Returns current host IP address.
#
# See https://stackoverflow.com/a/25851186
#
u_get_localhost_ip() {
  ip route get 1 | awk '{print $NF;exit}'
}

##
# Generates a slug from string.
#
# See https://gist.github.com/oneohthree/f528c7ae1e701ad990e6
#
# @param 1 String : the string to convert.
#
# @example
#   SLUG=$(u_slugify "A string with non-standard characters and accents. éàù!îôï. Test out!")
#   echo $SLUG # Result : "a-string-with-non-standard-characters-and-accents-eau-ioi-test-out"
#
u_slugify() {
  echo "${1}" | iconv -t ascii//TRANSLIT | sed -r s/[~\^]+//g | sed -r s/[^a-zA-Z0-9]+/-/g | sed -r s/^-+\|-+$//g | tr A-Z a-z
}

##
# Generates a slug from string - variant using underscores instead of dashes.
#
# @see u_slugify()
#
u_slugify_u() {
  echo "${1}" | iconv -t ascii//TRANSLIT | sed -r s/[~\^]+//g | sed -r s/[^a-zA-Z0-9]+/_/g | sed -r s/^_+\|_+$//g | tr A-Z a-z
}

##
# Prints bash script file absolute path (from where this function is called).
#
# @param 1 String : the bash script file - use ${BASH_SOURCE[0]} for the current
#   (calling) file.
#
# @example
#   FILE_ABS_PATH=$(u_get_script_path ${BASH_SOURCE[0]})
#
u_get_script_path() {
  echo $(cd "$(dirname "$1")" && pwd)/$(basename "$1")
}

##
# Checks if a package is missing from current system.
#
# See https://github.com/creationix/nvm/blob/master/nvm.sh
#
u_system_has() {
  type "${1-}" > /dev/null 2>&1
}
