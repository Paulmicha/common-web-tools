#!/usr/bin/env bash

##
# TODO [wip] Run tests.
#
# TODO evaluate plan : forward all arguments of this script to a hook call
# with predefined 'test' subject (that could be prefixed or suffixed with custom
# values).
#
# E.g. :
# $ hook -s 'test' -a "$1"
#
# @example (planned)
#   . cwt/bootstrap.sh
#   . cwt/test/run.sh 'cwt'
#
# @example (current WIP)
#   cwt/test/run.sh
#

. cwt/bootstrap.sh

# TODO prereq BATS installed - to provision (or bundle in a 'vendors' dir ?)
tf_path=cwt/test/cwt
bats_files=$(u_fs_file_list $tf_path 1 '*.bats')

for file in $bats_files; do
  bats "$tf_path/$file"
done
