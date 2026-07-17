#!/usr/bin/env bash

##
# [abstract] Triggers a generic 'logged loop' wrapped command.
#
# Composition: log/wrap → loop/wrap (systemd user unit for long-running entries).
#
# @example
#   # Manually hardcoded shortcut :
#   # @see CWT_MAKE_TASKS_SHORTER in cwt/env/global.vars.sh
#   make ll e:blueprint-generate
#   # Equivalent to :
#   make logged-loop e:blueprint-generate
#   # Or :
#   cwt/instance/logged_loop.sh e:blueprint-generate
#

. cwt/bootstrap.sh

logged_loop_variants='STACK_VERSION PROVISION_USING HOST_OS'

hook -s 'log' -p 'pre' -a 'logged_loop' -v "$logged_loop_variants"
hook -s 'loop' -p 'pre' -a 'logged_loop' -v "$logged_loop_variants"

cwt/log/wrap.sh cwt/loop/wrap.sh "$@"

hook -s 'log' -p 'post' -a 'logged_loop' -v "$logged_loop_variants"
hook -s 'loop' -p 'post' -a 'logged_loop' -v "$logged_loop_variants"
