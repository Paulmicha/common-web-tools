#!/usr/bin/env bash

##
# Implements hook -s 'cwt' -a 'bootstrap' -v 'PROVISION_USING'.
#
# Declares default bash aliases for current project instance using mysql.
#
# This file is dynamically included when the "hook" is triggered.
# @see cwt/bootstrap.sh
#
# Uses the docker exec interactive flag from 'docker-compose' extension.
# @see cwt/extensions/docker-compose/cwt/pre_bootstrap.docker-compose.hook.sh
#

alias mysql="docker-compose exec $DC_TTY ${MYSQL_SNAME:=mariadb} mysql"
alias mysqldump="docker-compose exec $DC_TTY ${MYSQL_SNAME:=mariadb} mysqldump"
