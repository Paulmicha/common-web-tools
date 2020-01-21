#!/usr/bin/env bash

##
# Implements hook -s 'cwt' -a 'alias' -v 'PROVISION_USING'.
#
# Declares default bash aliases for current project instance using a DB with
# 'pgsql' as driver.
#
# This file is dynamically included when the "hook" is triggered.
# @see cwt/bootstrap.sh
#
# Uses the docker exec interactive flag from 'docker-compose' extension.
# @see cwt/extensions/docker-compose/cwt/pre_bootstrap.docker-compose.hook.sh
#

alias psql="docker-compose exec $DC_TTY ${POSTGRES_SNAME:=postgres} psql"
alias pg_restore="docker-compose exec $DC_TTY ${POSTGRES_SNAME:=postgres} pg_restore"
alias dropdb="docker-compose exec $DC_TTY ${POSTGRES_SNAME:=postgres} dropdb"
alias createdb="docker-compose exec $DC_TTY ${POSTGRES_SNAME:=postgres} createdb"
