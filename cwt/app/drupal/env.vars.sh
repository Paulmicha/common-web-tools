#!/bin/bash

##
# Env settings model file.
#
# This file is dynamically included during stack init.
# @see cwt/stack/init.sh
# @see cwt/utilities/stack.sh
# @see cwt/utilities/env.sh
#
# Matching rules and syntax are explained in documentation :
# @see cwt/env/README.md
#

define DRUPAL_FILES_DIR "[default]=\$APP_DOCROOT/sites/default/files"
define DRUPAL_TMP_DIR "[default]=\$PROJECT_DOCROOT/tmp"
define DRUPAL_PRIVATE_DIR "[default]=\$PROJECT_DOCROOT/private"

define PROTECTED_FILES "[append]=\$APP_DOCROOT/sites/default/settings.php"

define WRITEABLE_DIRS "[append]=\$DRUPAL_FILES_DIR"
define WRITEABLE_DIRS "[append]=\$DRUPAL_TMP_DIR"
define WRITEABLE_DIRS "[append]=\$DRUPAL_PRIVATE_DIR"
