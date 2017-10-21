#!/bin/bash

##
# Project local instance permissions reset.
#
# @todo make generic.
#
# Directory structure :
# Files           = sites/default/files
# Private Files   = ../private
# Tmp             = sites/default/tmp
#
# Usage :
# . cwt/fixperms.sh
#

. cwt/env/load.sh

# Param 1 : owner
# default : current user
P_OWNER=${1}
if [ -z "${1}" ]; then
    P_OWNER="$USER"
fi

# Param 2 : group
# default : www-data
P_GROUP=${2}
if [ -z "${2}" ]; then
    P_GROUP="www-data"
fi

# Param 3 : path
# default : $APP_DOCROOT
P_PATH=${3}
if [ -z "${3}" ]; then
    P_PATH=$APP_DOCROOT
fi

# Param 4 : Non-writeable Files chmod
# default : 0640
P_NWFI=${4}
if [ -z "${4}" ]; then
    P_NWFI=0640
fi

# Param 5 : Non-writeable Folders chmod
# default : 0750
P_NWFO=${5}
if [ -z "${5}" ]; then
    P_NWFO=0750
fi

# Param 6 : Writeable Files chmod
# default : 0660
P_WFI=${6}
if [ -z "${6}" ]; then
    P_WFI=0660
fi

# Param 7 : Writeable Folders chmod
# default : 1771
P_WFO=${7}
if [ -z "${7}" ]; then
    P_WFO=1771
fi

# Project docroot initial permissions.
chown $P_OWNER:$P_GROUP . -R
chmod 0755 . -R

# Non-writeable files (drupal docroot).
find $P_PATH -type f -exec chmod $P_NWFI {} +

# Non-writeable dirs (drupal docroot).
find $P_PATH -type d -exec chmod $P_NWFO {} +

# Writeable files (drupal docroot).
find $P_PATH/$DRUPAL_FILES_FOLDER -type f -exec chmod $P_WFI {} +
find $P_PATH/$DRUPAL_TMP_FOLDER -type f -exec chmod $P_WFI {} +
find $P_PATH/$DRUPAL_PRIVATE_FILES_FOLDER -type f -exec chmod $P_WFI {} +

# Writeable dirs (drupal docroot).
find $P_PATH/$DRUPAL_FILES_FOLDER -type d  -exec chmod $P_WFO {} +
find $P_PATH/$DRUPAL_TMP_FOLDER -type d  -exec chmod $P_WFO {} +
find $P_PATH/$DRUPAL_PRIVATE_FILES_FOLDER -type d  -exec chmod $P_WFO {} +

# Protect settings file (drupal docroot).
chmod 0444 $P_PATH/sites/default/settings.php
