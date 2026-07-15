#!/usr/bin/env bash

##
# [abstract] Triggers a generic 'logged loop' wrapped command.
#
# Composition: log/wrap → loop/wrap (systemd user unit for long-running entries).
#
# This file is generated from template :
# @see {{ TEMPLATE }}
#
# @example
#   # Manually hardcoded shortcut :
#   # @see CWT_MAKE_TASKS_SHORTER in cwt/env/global.vars.sh
#   make ll e:agent-loop
#   # Equivalent to :
#   make logged-loop e:agent-loop
#   # Or :
#   cwt/instance/logged_loop.sh e:agent-loop
#

. cwt/bootstrap.sh

logged_loop_variants='STACK_VERSION PROVISION_USING HOST_OS'

hook -s 'log' -p 'pre' -a 'logged_loop' -v "$logged_loop_variants"
hook -s 'loop' -p 'pre' -a 'logged_loop' -v "$logged_loop_variants"

cwt/log/wrap.sh cwt/loop/wrap.sh "$@"

hook -s 'log' -p 'post' -a 'logged_loop' -v "$logged_loop_variants"
hook -s 'loop' -p 'post' -a 'logged_loop' -v "$logged_loop_variants"
