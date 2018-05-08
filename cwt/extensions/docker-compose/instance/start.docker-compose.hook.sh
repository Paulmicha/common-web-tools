#!/usr/bin/env bash

##
# Implements hook -s 'instance' -a 'start' -v 'PROVISION_USING INSTANCE_TYPE HOST_TYPE'
#
# Reacts to "instance start" for project instances using 'docker-compose' as
# provisioning method ($PROVISION_USING).
#

. cwt/extensions/docker-compose/stack/restart.sh
