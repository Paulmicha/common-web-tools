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

global TRAEFIK_VERSION "[default]=v2.4"

# Placeholder email address for Let's Encrypt Acme certificate resolver config.
# Docs : https://doc.traefik.io/traefik/https/acme
# @see cwt/extensions/remote_traefik/stack/acme_config.tpl.yml
global TRAEFIK_CERT_EMAIL "[default]=your-email@example.com [help]='Email address for Let’s Encrypt Acme certificate resolver config, see https://doc.traefik.io/traefik/https/acme'"

global TRAEFIK_BASIC_AUTH_USERS "[default]='$(u_str_basic_auth_credentials traefik_dashboard_creds)' [help]='Http Basic Auth credentials for traefik dashboard. Defauts to a randomly generated password that can be retrieved locally from a remote instance with the command : make remote-traefik-basic-auth (see cwt/extensions/remote_traefik/remote/traefik_basic_auth.sh)'"

global TRAEFIK_LOG_LEVEL "[default]='WARN'"

# Support optional systemd setup after instance init for auto-restart i.e. after
# host shutdown.
global TRAEFIK_SYSTEMD_SETUP "[default]='false' [help]='Set to true if you need to setup auto-restart i.e. after host shutdown using a systemd service. See cwt/extensions/remote_traefik/host/systemd_service_setup.sh'"

global TRAEFIK_SNAME "[default]=traefik"
global TRAEFIK_SYSTEMD_USER "$(u_print_current_user)"
global TRAEFIK_SYSTEMD_GROUP "docker"
