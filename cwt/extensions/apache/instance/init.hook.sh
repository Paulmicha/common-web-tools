#!/usr/bin/env bash

##
# Implements hook -a 'init' -v 'PROVISION_USING HOST_TYPE INSTANCE_TYPE'.
#
# @see u_instance_init() in cwt/instance/instance.inc.sh
#

case "$CWT_APACHE_INIT_VHOST" in true)
  u_apache_write_vhost_conf
esac
