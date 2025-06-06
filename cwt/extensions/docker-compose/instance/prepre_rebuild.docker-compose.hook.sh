#!/usr/bin/env bash

##
# Implements hook -p 'prepre' -s 'instance' -a 'rebuild' -v 'STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE'
#
# Reacts to "instance rebuild" for project instances using 'docker-compose' as
# provisioning method ($PROVISION_USING).
#
# @see cwt/instance/rebuild.sh
#

u_dc_instance_stop
