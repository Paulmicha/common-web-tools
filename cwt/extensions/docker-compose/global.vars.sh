#!/usr/bin/env bash

##
# Global (env) vars for the 'docker-compose' CWT extension.
#
# This file is used during "instance init" to generate the global environment
# variables specific to current project instance.
#
# @see u_instance_init() in cwt/instance/instance.inc.sh
# @see cwt/utilities/global.sh
# @see cwt/bootstrap.sh
#

# Important note : when using relative paths in docker-compose.yml files, the
# folder of the file itself is the reference.
# If it should instead be relative to PROJECT_DOCROOT, then the 'generate' mode
# is more suitable, that is : generating the (git-ignored) docker-compose.yml
# file in the right path (i.e. in PROJECT_DOCROOT).
global DC_MODE "[default]=none [help]='Specifies if and how docker-compose will choose a specific YAML declaration file for current project instance. Possible values are none = leave docker-compose calls untouched, auto = automatically try to choose the most specific YAML file based on the DC_YML_VARIANTS global (which provides hook variants for lookup paths), manual = use the path provided in the DC_YML global, or generate = creates the file PROJECT_DOCROOT/docker-compose.yml during instance init using the most specific match. Defaults to none.'"

case "$DC_MODE" in
  auto|generate)
    global DC_YML_VARIANTS "[default]='$INSTANCE_TYPE $HOST_TYPE' [help]='Determines which docker-compose.yml \"template\" will be used for current project instance.'"
    ;;
  manual)
    global DC_YML "[default]='docker-compose.yml' [help]='Specifies where docker-compose will find the YAML declaration file to use for current project instance.'"
    ;;
esac

# [optional] Shorter generated make tasks names.
# @see u_instance_task_name() in cwt/instance/instance.inc.sh
global CWT_MAKE_TASKS_SHORTER "[append]='docker-compose/dc'"
