#!/usr/bin/env bash

##
# Drupal app setup.
#
# This script will :
# - write settings
# - create git-ignored instance folders
# - set permissions
# - create instance DB
# - import initial DB dump (requires manual operation : file dumps/initial.sql.gz must exist)
#
# This script is idempotent (can be run several times without issue).
#
# Run as root or sudo.
#
# Usage :
# $ . cwt/app/drupal/7/setup.sh
#

. cwt/env/load.sh

. cwt/app/drupal/7/write_settings.sh

mkdir -p $APP_DOCROOT/$DRUPAL_FILES_FOLDER
mkdir -p $APP_DOCROOT/$DRUPAL_TMP_FOLDER

. cwt/fixperms.sh

. cwt/db/mysql/setup.sh
. cwt/db/drush/import_initial.sh
