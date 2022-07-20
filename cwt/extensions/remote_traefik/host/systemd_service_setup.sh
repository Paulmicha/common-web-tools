#!/usr/bin/env bash

##
# Setup systemd service for auto restart after host shutdown.
#
# See https://techoverflow.net/2020/09/21/traefik-docker-compose-configuration-with-secure-dashboard-and-lets-encrypt/
#

. cwt/bootstrap.sh

systemd_service_conf="/etc/systemd/system/$TRAEFIK_SNAME.service"

# (Over)write config file in its final destination.
if [[ -f "$systemd_service_conf" ]]; then
  rm -f "$systemd_service_conf"
fi
cp "cwt/extensions/remote_traefik/host/systemd_service_conf.tpl.service" "$systemd_service_conf"

# Replace read-only global vars (supports any global) placeholders.
u_global_list
for var_name in "${cwt_globals_var_names[@]}"; do
  if grep -Fq "{{ ${var_name} }}" "$traefik_conf"; then
    var_val="${!var_name}"
    sed -e "s,{{ ${var_name} }},${var_val},g" -i "$systemd_service_conf"
    # Debug.
    # echo "replaced '{{ ${var_name} }}' by '${var_val}'"
  fi
done

systemctl enable "$TRAEFIK_SNAME.service"
systemctl start "$TRAEFIK_SNAME.service"
