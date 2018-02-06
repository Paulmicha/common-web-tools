#!/usr/bin/env bash

##
# Global env settings declaration.
#
# This file is dynamically included during stack init. Matching rules and syntax
# are explained in documentation.
# @see cwt/env/README.md
#

global DRUPAL_FILES_DIR "[default]=$APP_DOCROOT/sites/default/files"
global DRUPAL_TMP_DIR "[default]=$PROJECT_DOCROOT/tmp"
global DRUPAL_PRIVATE_DIR "[default]=$PROJECT_DOCROOT/private"

global DRUPAL_SETTINGS "[default]=$APP_DOCROOT/sites/default/settings.local.php"
global DRUPAL_LOCAL_SETTINGS "[default]=$APP_DOCROOT/sites/default/settings.local.php"

global PROTECTED_FILES "[append]=$DRUPAL_SETTINGS"
global PROTECTED_FILES "[append]=$DRUPAL_LOCAL_SETTINGS"

global WRITEABLE_DIRS "[if-PROVISION_USING]=scripts [append]=$DRUPAL_FILES_DIR"
global WRITEABLE_DIRS "[if-PROVISION_USING]=scripts [append]=$DRUPAL_TMP_DIR"
global WRITEABLE_DIRS "[if-PROVISION_USING]=scripts [append]=$DRUPAL_PRIVATE_DIR"
# global WRITEABLE_DIRS "[index]=1 [append]=$DRUPAL_FILES_DIR"
# global WRITEABLE_DIRS "[index]=1 [append]=$DRUPAL_TMP_DIR"
# global WRITEABLE_DIRS "[index]=1 [append]=$DRUPAL_PRIVATE_DIR"
