#!/usr/bin/env bash

##
# Implements hook -s 'instance' -a 'stop' -v 'PROVISION_USING INSTANCE_TYPE HOST_TYPE'
#
# Reacts to "instance stop" for project instances using 'docker-compose' as
# provisioning method ($PROVISION_USING).
#

docker-compose stop
