#!/usr/bin/env bash

##
# Implements hook -s 'cwt' -a 'pre_bootstrap' -v 'PROVISION_USING'.
#
# Provide a global variable allowing to conditionally handle the pseudo-tty
# allocation for "docker-compose run" and "docker-compose exec" commands. See
# example below for how to use this in custom aliases.
#
# See https://docs.docker.com/compose/reference/run/
# See https://docs.docker.com/compose/reference/exec/
# See https://unix.stackexchange.com/questions/26676/how-to-check-if-a-shell-is-login-interactive-batch
#
# @see cwt/bootstrap.sh
#
# @example
#   # Only use pseudo-tty allocation if current shell is interactive.
#   # By default 'docker-compose exec|run' allocates a TTY.
#   alias npx="docker-compose exec $DC_TTY web npx"
#

DC_TTY='-T'
case $- in *i*)
  DC_TTY=''
esac
