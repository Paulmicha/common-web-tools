#!/bin/bash

##
# Global env settings declaration.
#
# This file is dynamically included during stack init. Matching rules and syntax
# are explained in documentation.
# @see cwt/env/README.md
#

global DRUPAL_CONFIG_SYNC_DIR "[default]=$APP_GIT_WORK_TREE/config/sync"
global WRITEABLE_DIRS "[append]=$DRUPAL_CONFIG_SYNC_DIR"
