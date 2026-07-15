#!/usr/bin/env bash

##
# Implements hook -s 'cwt' -a 'alias' -v 'STACK_VERSION PROVISION_USING'.
#
# Declares default bash aliases for current project instance.
#
# This file is dynamically included when the "hook" is triggered.
# @see cwt/bootstrap.sh
#
# Uses the docker exec interactive flag from 'compose' extension.
# @see cwt/extensions/compose/cwt/pre_bootstrap.compose.hook.sh
#

php_sname="${PHP_SNAME:=php}"

alias php="docker compose exec $DC_TTY $php_sname php"
