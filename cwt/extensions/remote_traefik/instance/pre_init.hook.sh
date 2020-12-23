#!/usr/bin/env bash

##
# Implements hook -a 'init' -p 'pre'.
#

u_traefik_generate_acme_conf

# This is the shared network to use in order to expose other docker-compose
# stacks services through this traefik reverse proxy instance.
# See https://dev.to/cedrichopf/get-started-with-traefik-2-using-docker-compose-35f9
# Update : we're no longer using this approach, as it would would require some
# bridge network configuration to only share some stack services with the proxy
# (otherwise they wouldn't be able to communicate with other services of their
# stack once moved in the 'proxy' network).
# -> Falling back to the docker4drupal approach :
# @see https://github.com/wodby/docker4drupal/blob/master/traefik.yml
# docker network create proxy 2>/dev/null
