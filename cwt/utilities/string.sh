#!/bin/bash

##
# String-related utility functions.
#
# This script is dynamically loaded.
# @see cwt/bash_utils.sh
#
# Convention : fonctions names are all prefixed by "u" (for "utility").
#

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
