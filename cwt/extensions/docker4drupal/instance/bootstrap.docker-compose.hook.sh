#!/usr/bin/env bash

##
# Implements hook -a 'bootstrap' -v 'PROVISION_USING'.
#
# Declares bash aliases for project stacks using docker4drupal.
#
# This file is dynamically included when the "hook" is triggered.
# @see cwt/bootstrap.sh
#

alias composer="docker-compose exec --user 82 php composer"
alias composersu="docker-compose exec php composer"
alias drush="docker-compose exec --user 82 php drush --root=/var/www/html/web"
alias drupal="docker-compose exec --user 82 php ./vendor/drupal/console/bin/drupal --root=/var/www/html/web"
