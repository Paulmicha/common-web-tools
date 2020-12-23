#!/usr/bin/env bash

##
# Instance initialization process ("instance init").
#
# @example
#   # Calling this script without any arguments will use prompts in terminal
#   # to provide values for every globals.
#   cwt/instance/init.sh
#
#   # Initializes an instance of type 'dev', host type 'local', provisionned
#   # using 'ansible', identified by domain 'dev.cwt.com', using 'cwt_dev' as
#   # docker-compose namespace, with git origin
#   'git@my-git-origin.org:my-git-account/cwt.git', app sources cloned in 'dist',
#   # and using 'dist/web' as app dir - without terminal prompts (-y flag).
#   u_instance_init \
#     -t 'dev' \
#     -h 'local' \
#     -p 'ansible' \
#     -d 'dev.cwt.com' \
#     -c 'cwt_dev' \
#     -g 'git@my-git-origin.org:my-git-account/cwt.git' \
#     -a 'dist' \
#     -s 'dist/web' \
#     -y
#

# This action can be (re)launched after local instance was already initialized,
# and in this case, we cannot have 'readonly' variables automatically loaded
# during CWT bootstrap -> so we use that var as a flag to avoid it.
# @see cwt/bootstrap.sh
CWT_BS_SKIP_GLOBALS=1

. cwt/bootstrap.sh

u_instance_init "$@"
