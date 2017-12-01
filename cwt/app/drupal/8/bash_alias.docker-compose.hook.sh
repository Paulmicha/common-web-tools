#!/bin/bash

##
# Implements u_hook_app_call 'bash' 'alias'.
#
# This file is dynamically included when the "hook" is triggered.
#

# [wip] TODO avoid hardcoded service name - touches upon services configurability.
alias composer="docker-compose exec --user 82 php composer"

# [wip] TODO avoid hardcoded root path.
alias drush="docker-compose exec --user 82 php drush --root=/var/www/html/web"

# See https://github.com/hechoendrupal/drupal-console/issues/2515
# alias drupal="docker-compose exec --user 82 php drupal --root=/var/www/html/web"
# alias drupal="docker-compose exec --user 82 php ./vendor/drupal/console/bin/drupal --root=/var/www/html/web"
