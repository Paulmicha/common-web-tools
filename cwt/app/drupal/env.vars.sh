#!/bin/bash

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

global PROTECTED_FILES "[append]=$APP_DOCROOT/sites/default/settings.php"

global WRITEABLE_DIRS "[append]=$DRUPAL_FILES_DIR"
global WRITEABLE_DIRS "[append]=$DRUPAL_TMP_DIR"
global WRITEABLE_DIRS "[append]=$DRUPAL_PRIVATE_DIR"
