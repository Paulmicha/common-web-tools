#!/usr/bin/env bash

##
# Implements hook -s 'instance' -a 'wait_for' -v 'PROVISION_USING HOST_TYPE INSTANCE_TYPE'
#
# Wait until the database container accepts connections. Examples :
# See https://github.com/wodby/docker4drupal/blob/master/tests/8/run.sh
# See https://github.com/wodby/mariadb/blob/master/10/bin/actions.mk
# See https://github.com/wodby/alpine/blob/master/bin/wait_for
# @see cwt/utilities/shell.sh
# @see cwt/extensions/docker-compose/instance/start.docker-compose.hook.sh
# @see cwt/extensions/docker-compose/instance/instance.inc.sh
# @see cwt/instance/start.sh
#
# Uses bash aliases defined for mariadb (mysql).
# @see cwt/extensions/mysql/cwt/alias.docker-compose.hook.sh
#

u_db_set

cmd=$(cat <<'EOF'
mysqladmin \
  --user="$DB_ADMIN_USER" \
  --password="$DB_ADMIN_PASS" \
  --host="$DB_HOST" \
  --port="$DB_PORT" \
  status &> /dev/null
EOF
)

wait_for "MySQL" "$cmd"
