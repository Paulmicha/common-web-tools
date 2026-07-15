#!/usr/bin/env bash

##
# Implements hook -s 'instance' -a 'start' -v 'STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE'
#
# Reacts to "instance start" for project instances using 'compose' as
# provisioning method ($PROVISION_USING).
#
# @see cwt/extensions/compose/instance/instance.inc.sh
#

u_dc_instance_start
