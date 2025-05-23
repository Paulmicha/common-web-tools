#!/usr/bin/env bash

##
# Implements hook -s 'instance' -a 'stop' -v 'STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE'
#
# Reacts to "instance stop" for project instances using 'docker-compose' as
# provisioning method ($PROVISION_USING).
#
# @see cwt/extensions/docker-compose/instance/instance.inc.sh
#

u_dc_instance_stop
