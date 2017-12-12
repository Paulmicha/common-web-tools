#!/usr/bin/env bash

##
# Implements u_hook_app 'bash' 'alias'.
#
# [wip] TODO avoid hardcoded service names ("services configurability" currently
# missing in CWT) and root paths (Docker volume relative - e.g. :
# /var/www/html/web).
#
# Drupal console note :
# See https://github.com/hechoendrupal/drupal-console/issues/2515
#
# This file is dynamically included when the "hook" is triggered.
#

echo "($BASH_SOURCE loaded by u_hook_app $@)"

alias composer="docker-compose exec --user 82 php composer"
alias drush="docker-compose exec --user 82 php drush --root=/var/www/html/web"
alias drupal="docker-compose exec --user 82 php ./vendor/drupal/console/bin/drupal --root=/var/www/html/web"
