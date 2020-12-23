#!/usr/bin/env bash

##
# Implements hook -a 'init' -p 'post'.
#

case "$TRAEFIK_SYSTEMD_SETUP" in 'true')
  sudo cwt/extensions/remote_traefik/host/systemd_service_setup.sh
esac
