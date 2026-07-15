#!/usr/bin/env bash

##
# Bootstrap phase: source CWT core utilities (fixed order).
#
# Sourced only from cwt/bootstrap.sh (inside CWT_BS_FLAG).
#
# @see cwt/bootstrap.sh
#

# Include CWT core utilities.
. cwt/utilities/shell.sh
. cwt/utilities/cwt.sh
. cwt/utilities/global.sh
. cwt/utilities/hook.sh
. cwt/utilities/autoload.sh
. cwt/utilities/fs.sh
. cwt/utilities/array.sh
. cwt/utilities/string.sh
. cwt/utilities/yaml.sh
