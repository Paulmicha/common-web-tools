#!/usr/bin/env bash

##
# Implements hook -a 'init' -v 'PROVISION_USING HOST_TYPE INSTANCE_TYPE'.
#
# This global specifies if and how docker-compose will choose a YAML declaration
# file for current project instance.
#
# When set to 'generate', the docker-compose.yml file will be written during
# 'instance init'.
#
# @see cwt/extensions/docker-compose/global.vars.sh
# @see u_dc_write_yml() in cwt/extensions/docker-compose/docker-compose.inc.sh
# @see u_instance_init() in cwt/instance/instance.inc.sh
#

case "$DC_MODE" in 'generate')
  u_dc_write_yml
esac
