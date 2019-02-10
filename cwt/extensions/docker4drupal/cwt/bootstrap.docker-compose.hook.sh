#!/usr/bin/env bash

##
# Implements hook -s 'cwt' -a 'bootstrap' -v 'PROVISION_USING'.
#
# Declares default bash aliases for current project instance using d4d.
#
# This file is dynamically included when the "hook" is triggered.
# @see cwt/bootstrap.sh
#
# Uses the docker exec interactive flag from 'docker-compose' extension.
# @see cwt/extensions/docker-compose/cwt/pre_bootstrap.docker-compose.hook.sh
#

alias php="docker-compose exec $DC_TTY ${D4D_PHP_SNAME:=php} php"

alias composer="docker-compose exec $DC_TTY ${D4D_PHP_SNAME:=php} composer"
alias composersu="docker-compose exec $DC_TTY --user root ${D4D_PHP_SNAME:=php} composer"

alias drush="docker-compose exec $DC_TTY ${D4D_PHP_SNAME:=php} drush --root=${D4D_PUBLIC_DOCROOT:=/var/www/html}"
alias drupal="docker-compose exec $DC_TTY ${D4D_PHP_SNAME:=php} ./vendor/drupal/console/bin/drupal --root=${D4D_PUBLIC_DOCROOT:=/var/www/html}"

alias mysql="docker-compose exec $DC_TTY ${D4D_DB_SNAME:=mariadb} mysql"
alias mysqldump="docker-compose exec $DC_TTY ${D4D_DB_SNAME:=mariadb} mysqldump"

# [debug] log current instance domain (check remote calls).
# echo "Bash aliases loaded ($INSTANCE_DOMAIN)."
