#!/usr/bin/env bash

##
# Internal debug utility.
#
# Prints back the args (corresponds the the 'debug' hardcoded Make entry point).
# @see cwt/make/default.mk
#
# @example
#   make debug ev $(cwt/escape.sh '$test = "Printed from Drupal php"; print $test;')
#   # Outputs :
#   Args passed to script :
#     1 : ev
#     2 : $test = "Printed from Drupal php"; print $test;
#

. cwt/bootstrap.sh

echo "Args passed to script :"
echo
echo "  1 : $1"
echo "  2 : $2"
echo "  3 : $3"
echo "  4 : $4"
echo "  5 : $5"
echo "  6 : $6"
echo "  7 : $7"
echo "  8 : $8"
echo "  9 : $9"
echo
