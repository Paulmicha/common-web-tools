#!/bin/bash

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
# $ . cwt/app/drupal_setup.sh
#

. cwt/env/load.sh

. cwt/app/write_settings.sh

mkdir -p $APP_DOCROOT/$DRUPAL_FILES_FOLDER
mkdir -p $APP_DOCROOT/$DRUPAL_TMP_FOLDER

. cwt/fixperms.sh

. cwt/db/setup.sh
. cwt/db/import_initial.sh
