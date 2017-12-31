#!/usr/bin/env bash

##
# [wip] Run tests.
#
# Usage :
# $ cwt/test/run.sh
#

# [wip] debug.
for file in $(find cwt/test/cwt -maxdepth 1 -type f -print0 | xargs -0); do
  bats "$file"
done
