#!/usr/bin/env bash

##
# Global (env) vars for the 'remote_traefik' CWT extension.
#
# This file is used during "instance init" to generate the global environment
# variables specific to current project instance.
#
# @see u_instance_init() in cwt/instance/instance.inc.sh
# @see cwt/utilities/global.sh
# @see cwt/bootstrap.sh
#

global TRAEFIK_VERSION "[default]=2.3"

# Placeholder email address for Let's Encrypt Acme certificate resolver config.
# Docs : https://doc.traefik.io/traefik/https/acme
# @see cwt/extensions/remote_traefik/stack/acme_config.tpl.yml
global TRAEFIK_CERT_EMAIL "[default]=your-email@example.com [help]='Email address for Let’s Encrypt Acme certificate resolver config, see https://doc.traefik.io/traefik/https/acme'"

global TRAEFIK_BASIC_AUTH_USERS "[default]='$(u_traefik_basic_auth_credentials)'"

# Support optional systemd setup after instance init for auto-restart i.e. after
# host shutdown.
global TRAEFIK_SYSTEMD_SETUP "[default]='false' [help]='Set to true if you need to setup auto-restart i.e. after host shutdown using a systemd service. See cwt/extensions/remote_traefik/host/systemd_service_setup.sh'"

global TRAEFIK_SNAME "[default]=traefik"
global TRAEFIK_SYSTEMD_USER "$(u_print_current_user)"
global TRAEFIK_SYSTEMD_GROUP "docker"
