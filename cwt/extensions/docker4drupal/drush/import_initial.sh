#!/usr/bin/env bash

##
# Restore DB dump.
#
# Usage example from project root dir :
# $ . cwt/db/drush/import_initial.sh
#

# TODO [wip] refacto in progress.

# . cwt/env/load.sh

# # Make temp copy.
# cp dumps/initial.sql.gz web/initial.sql.gz
# gunzip web/initial.sql.gz

# # Restore initial dump.
# drush sql-drop -y
# drush sql-query --file="initial.sql"
# # mysql -h localhost -u$DB_USERNAME -p$DB_PASSWORD --default_character_set=utf8 $DB_NAME < web/initial.sql

# # Remove temporary copy.
# rm "web/initial.sql"
