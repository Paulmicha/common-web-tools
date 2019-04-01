
##
# Add custom 'make' entry points (CLI shortcuts).
#
# This file is included in the Makefile from project docroot once instance init
# has generated an .env file.
#
# @see cwt/extensions/drupalwt/cli/drush.make.sh
# @see cwt/extensions/drupalwt/cli/drupal.make.sh
# @see cwt/extensions/drupalwt/cli/composer.make.sh
# @see Makefile
# @see .env
#

.PHONY: drush
drush:
	@ cwt/extensions/drupalwt/cli/drush.make.sh $(filter-out $@,$(MAKECMDGOALS))

.PHONY: drupal
drupal:
	@ cwt/extensions/drupalwt/cli/drupal.make.sh $(filter-out $@,$(MAKECMDGOALS))

.PHONY: composer
composer:
	@ cwt/extensions/drupalwt/cli/composer.make.sh $(filter-out $@,$(MAKECMDGOALS))
