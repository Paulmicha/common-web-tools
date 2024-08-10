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

global DC_BIN_PATH "[default]=/usr/local/bin"

global DC_STACK_VERSION "[default]=1 [help]='A number (integer) that is used for example when we upgrade one or more services (or the whole stack). See cwt/extensions/docker-compose/stack/switch.sh'"

# Important note : when using relative paths in docker-compose.yml files, the
# folder of the file itself is the reference.
# If it should instead be relative to PROJECT_DOCROOT, then the 'generate' mode
# is more suitable, that is : generating the (git-ignored) docker-compose.yml
# file in the right path (i.e. in PROJECT_DOCROOT).
global DC_MODE "[default]=generate [help]='Specifies if and how docker-compose will choose a specific YAML declaration file for current project instance. Possible values are none = leave docker-compose calls untouched, auto = automatically try to choose the most specific YAML file based on the DC_YML_VARIANTS global (which provides hook variants for lookup paths), manual = use the path provided in the DC_YML global, or generate = creates the file PROJECT_DOCROOT/docker-compose.yml during instance init using the most specific match. Defaults to ’generate’.'"

global DC_NS "[default]='$(u_dc_default_namespace)' [help]='Docker-compose namespace is used for container names to match traefik labels. It must be unique (per instance).'"

# The following globals are set to use deferred value assignment in order to
# allow applying defaults when DC_MODE is set in another global.vars.sh file.
case "$DC_MODE" in
  auto|generate)
    global DC_YML_VARIANTS "[default]='$HOST_TYPE $INSTANCE_TYPE v$DC_STACK_VERSION' [help]='Hook variants to determine which docker-compose.yml (and optionally docker-compose.override.yml) will be matched for use in current project instance. Defaults to ’HOST_TYPE INSTANCE_TYPE’.'"
    ;;
  manual)
    global DC_YML "[default]='docker-compose.yml' [help]='Specifies where docker-compose will find the YAML declaration file to use for current project instance.'"
    global DC_OVERRIDE_YML "[default]='docker-compose.override.yml' [help]='Specifies where docker-compose will find the docker-compose.override.yml file to use for current project instance.'"
    ;;
esac

# Subdomain or prefix separator for use in Traefik labels.
global DC_SUBDOMAIN_SEP "[default]='.' [help]='Subdomain or prefix separator for use in Traefik labels. E.g. if instance domain is example.com, one of its services could want to use backend.example.com -> separator = ’.’ in this case. Otherwise, if instance domain is stage.example.com, a service wanting another subdomain would be mailhog-stage.example.com -> here, separator = ’-’.'"

# [optional] Shorter generated make tasks names.
# @see u_make_task_name() in cwt/instance/instance.inc.sh
global CWT_MAKE_TASKS_SHORTER "[append]='docker-compose/dc'"
global CWT_MAKE_TASKS_SHORTER "[append]='service-exec/se'"
global CWT_MAKE_TASKS_SHORTER "[append]='service-run/sr'"
