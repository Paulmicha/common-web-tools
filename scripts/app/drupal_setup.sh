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
# $ . scripts/app/drupal_setup.sh
#

. scripts/env/load.sh

. scripts/app/write_settings.sh

mkdir -p $APP_DOCROOT/$DRUPAL_FILES_FOLDER
mkdir -p $APP_DOCROOT/$DRUPAL_TMP_FOLDER

. scripts/fixperms.sh

. scripts/db/setup.sh
. scripts/db/import_initial.sh
