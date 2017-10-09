#!/bin/bash

##
# Restore DB dump.
#
# Usage example from project root dir :
# $ . scripts/db/import_initial.sh
#

. scripts/env/load.sh

# Make temp copy.
cp dumps/initial.sql.gz web/initial.sql.gz
gunzip web/initial.sql.gz

# Restore initial dump.
drush sql-drop -y
drush sql-query --file="initial.sql"
# mysql -h localhost -u$DB_USERNAME -p$DB_PASSWORD --default_character_set=utf8 $DB_NAME < web/initial.sql

# Remove temporary copy.
rm "web/initial.sql"
